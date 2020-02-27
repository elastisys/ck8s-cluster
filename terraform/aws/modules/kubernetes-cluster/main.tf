locals {
  internal_cidr_prefix = "172.16.0.0/16"
}


# VPC

resource "aws_vpc" "main" {
  cidr_block = local.internal_cidr_prefix

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}


# Subnet

resource "aws_subnet" "main_sn" {
  vpc_id     = aws_vpc.main.id
  cidr_block = aws_vpc.main.cidr_block

  tags = {
    Name = "${var.prefix}-main-sn"
  }
}


# Internet gateway

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-gateway"
  }
}


# Routing

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-rt"
  }
}

resource "aws_route" "egress_via_gateway" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "rtassociation" {
  subnet_id      = aws_subnet.main_sn.id
  route_table_id = aws_route_table.rt.id
}


# Master loadbalancer

resource "aws_lb" "master_lb_external" {
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.main_sn.id]

  tags = {
    Name = "${var.prefix}-master-lb-external"
  }
}

resource "aws_lb" "master_lb_internal" {
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.main_sn.id]

  tags = {
    Name = "${var.prefix}-master-lb-internal"
  }
}

resource "aws_lb_target_group" "master_tg_external" {
  name        = "${var.prefix}-master-tg-external"
  port        = 6443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group" "master_tg_internal" {
  name        = "${var.prefix}-master-tg-internal"
  port        = 6443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "master_tga_external" {
  for_each = aws_instance.master

  target_group_arn = aws_lb_target_group.master_tg_external.arn
  target_id        = each.value.private_ip
  port             = 6443
}

resource "aws_lb_target_group_attachment" "master_tga_internal" {
  for_each = aws_instance.master

  target_group_arn = aws_lb_target_group.master_tg_internal.arn
  target_id        = each.value.private_ip
  port             = 6443
}

resource "aws_lb_listener" "master_listener_external" {
  load_balancer_arn = aws_lb.master_lb_external.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master_tg_external.arn
  }
}

resource "aws_lb_listener" "master_listener_internal" {
  load_balancer_arn = aws_lb.master_lb_internal.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master_tg_internal.arn
  }
}


# Cluster security group + rules

resource "aws_security_group" "cluster_sg" {
  name        = "${var.prefix}-cluster_sg"
  description = "CK8s cluster security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-cluster-sg"
  }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.public_ingress_cidr_whitelist
  security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "internal_ingress_allow_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  self              = true
  security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "egress_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster_sg.id
}


# Master security group + rules

resource "aws_security_group" "master_sg" {
  name        = "${var.prefix}-master_sg"
  description = "CK8s master security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-master-sg"
  }
}

resource "aws_security_group_rule" "kube_api_external" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.public_ingress_cidr_whitelist
  security_group_id = aws_security_group.master_sg.id
}

resource "aws_security_group_rule" "kube_api_internal" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.master_sg.id
}


# Worker security group + rules

resource "aws_security_group" "worker_sg" {
  name        = "${var.prefix}-worker_sg"
  description = "CK8s worker security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-worker-sg"
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.public_ingress_cidr_whitelist
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.public_ingress_cidr_whitelist
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = var.public_ingress_cidr_whitelist
  security_group_id = aws_security_group.worker_sg.id
}


# AWS keys

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


# Master instance

resource "aws_instance" "master" {
  for_each = var.master_nodes

  connection {
    user = "ubuntu"
    host = self.public_ip
  }

  associate_public_ip_address = true

  instance_type          = each.value
  ami                    = lookup(var.aws_amis, var.aws_region)
  vpc_security_group_ids = [aws_security_group.master_sg.id, aws_security_group.cluster_sg.id]
  subnet_id              = aws_subnet.main_sn.id
  iam_instance_profile   = aws_iam_instance_profile.master.name
  key_name = aws_key_pair.auth.key_name

  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name = "${var.prefix}-${each.key}"
  }
}


# Worker instance

resource "aws_instance" "worker" {
  for_each = var.worker_nodes

  connection {
    user = "ubuntu"
    host = self.public_ip
  }

  associate_public_ip_address = true

  instance_type          = each.value
  ami                    = lookup(var.aws_amis, var.aws_region)
  vpc_security_group_ids = [aws_security_group.worker_sg.id, aws_security_group.cluster_sg.id]
  subnet_id              = aws_subnet.main_sn.id
  iam_instance_profile   = aws_iam_instance_profile.worker.name
  key_name = aws_key_pair.auth.key_name

  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name = "${var.prefix}-${each.key}"
  }
}
