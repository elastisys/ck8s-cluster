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
