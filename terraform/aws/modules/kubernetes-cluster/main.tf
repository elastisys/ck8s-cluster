# Heavily inspired by HA cluster installer
# https://github.com/elastisys/hakube-installer

locals {
  vpc_cidr_prefix    = "172.16.0.0/16"
  subnet_cidr_prefix = "172.16.1.0/24"
}

provider "template" {
  version = "~> 2.1"
}

# VPC

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr_prefix

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                  = "${var.prefix}-vpc"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
  }
}


# Subnet

resource "aws_subnet" "main_sn" {
  vpc_id     = aws_vpc.main.id
  cidr_block = local.subnet_cidr_prefix

  tags = {
    Name                                  = "${var.prefix}-main-sn"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
  }
}


# Internet gateway

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name                                  = "${var.prefix}-gateway"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
  }
}


# Routing

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name                                  = "${var.prefix}-rt"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
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


# External master loadbalancer

# security group allowing traffic from permitted ip ranges to the
# public apiserver loadbalancer
resource "aws_security_group" "master-lb-ext-sg" {
  description = "allow selected IP addresses to access public apiserver LB"
  vpc_id      = aws_vpc.main.id

  # outgoing traffic from LB allowed to go anywhere
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "6443"
    to_port     = "6443"
    protocol    = "tcp"
    cidr_blocks = var.api_server_whitelist
  }

  tags = {
    Name = "${var.prefix}-master-lb-ext-sg"
  }
}

# public (internet-facing) master network loadbalancer
resource "aws_elb" "master_lb_ext" {
  subnets         = [aws_subnet.main_sn.id]
  internal        = false
  security_groups = [aws_security_group.master-lb-ext-sg.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  # connection idle timeout in seconds
  idle_timeout                = 300
  cross_zone_load_balancing   = true
  connection_draining         = false
  connection_draining_timeout = 300

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "SSL:6443"
    interval            = 10
  }

  tags = {
    Name = "${var.prefix}-master-lb-ext"
  }
}

resource "aws_elb_attachment" "public_elb_masters" {
  for_each = aws_instance.master

  elb      = aws_elb.master_lb_ext.id
  instance = each.value.id
}

# Internal master loadbalancer

# security group allowing all traffic originating from private IPs within
# the VPC access to the internal loadbalancer
resource "aws_security_group" "master_lb_int_sg" {
  description = "allow access to internal LB from all private IPs in VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # outgoing traffic from LB allowed to go anywhere
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-master-lb-int-sg"
  }
}

# internal apiserver loadbalancer that will be used internally by
# kubernetes nodes
resource "aws_elb" "master_lb_int" {
  subnets         = [aws_subnet.main_sn.id]
  internal        = true
  security_groups = [aws_security_group.master_lb_int_sg.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  # connection idle timeout in seconds
  idle_timeout                = 300
  cross_zone_load_balancing   = true
  connection_draining         = false
  connection_draining_timeout = 300

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "SSL:6443"
    interval            = 10
  }

  tags = {
    Name = "${var.prefix}-master-lb-int"
  }
}

resource "aws_elb_attachment" "internal_elb_masters" {
  for_each = aws_instance.master

  elb      = aws_elb.master_lb_int.id
  instance = each.value.id
}


# Cluster security group + rules

resource "aws_security_group" "cluster_sg" {
  name        = "${var.prefix}-cluster_sg"
  description = "CK8s cluster security group"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to ingress to ignore k8s ELB ingress
      ingress
    ]
  }

  tags = {
    Name                                  = "${var.prefix}-cluster-sg"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
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
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = var.nodeport_whitelist
  security_group_id = aws_security_group.worker_sg.id
}


# AWS keys

resource "aws_key_pair" "auth" {
  key_name   = "${var.prefix}-ssh"
  public_key = file(var.ssh_pub_key)
}


# Master instance

resource "aws_instance" "master" {
  for_each = {
    for name, machine in var.machines : name => machine
    if machine.node_type == "master"
  }

  connection {
    user = "ubuntu"
    host = self.public_ip
  }

  associate_public_ip_address = true

  instance_type          = each.value.size
  ami                    = each.value.image
  vpc_security_group_ids = [aws_security_group.master_sg.id, aws_security_group.cluster_sg.id]
  subnet_id              = aws_subnet.main_sn.id
  iam_instance_profile   = aws_iam_instance_profile.master.name
  key_name               = aws_key_pair.auth.key_name

  # Required for AWS in-tree cloud provider at the moment.
  # Hostname must match node name specified by cloud provider.
  user_data = <<-EOF
  #!/bin/bash
  hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
  EOF

  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name                                  = "${var.prefix}-${each.key}"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
  }
}


# Worker instance

resource "aws_instance" "worker" {
  for_each = {
    for name, machine in var.machines : name => machine
    if machine.node_type == "worker"
  }

  connection {
    user = "ubuntu"
    host = self.public_ip
  }

  associate_public_ip_address = true

  instance_type          = each.value.size
  ami                    = each.value.image
  vpc_security_group_ids = [aws_security_group.worker_sg.id, aws_security_group.cluster_sg.id]
  subnet_id              = aws_subnet.main_sn.id
  iam_instance_profile   = aws_iam_instance_profile.worker.name
  key_name               = aws_key_pair.auth.key_name

  # Required for AWS in-tree cloud provider at the moment.
  # Hostname must match node name specified by cloud provider.
  user_data = <<-EOF
  #!/bin/bash
  hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
  EOF

  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name                                  = "${var.prefix}-${each.key}"
    "kubernetes.io/cluster/${var.prefix}" = "owned"
  }
}


# IAM roles, policies, profiles
# See https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/aws_iam

resource "aws_iam_instance_profile" "master" {
  name = "${var.prefix}-master"
  role = aws_iam_role.master.name
}

resource "aws_iam_role" "master" {
  name = "${var.prefix}-master-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "master" {
  name = "${var.prefix}-master-policy"
  role = aws_iam_role.master.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["ec2:*"],
        "Resource": ["*"]
      },
      {
        "Effect": "Allow",
        "Action": ["elasticloadbalancing:*"],
        "Resource": ["*"]
      },
      {
        "Effect": "Allow",
        "Action": ["route53:*"],
        "Resource": ["*"]
      },
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
          "arn:aws:s3:::kubernetes-*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.prefix}-worker"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role" "worker" {
  name = "${var.prefix}-worker-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "worker" {
  name = "${var.prefix}-worker-policy"
  role = aws_iam_role.worker.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
          "arn:aws:s3:::kubernetes-*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "ec2:Describe*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ec2:AttachVolume",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ec2:DetachVolume",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": ["route53:*"],
        "Resource": ["*"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}
