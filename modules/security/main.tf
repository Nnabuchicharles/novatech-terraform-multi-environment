resource "aws_security_group" "web" {
  name_prefix = "${var.project}-${var.environment}-web-"
  description = "Outbound allowed; optional inbound HTTP demo access"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-${var.environment}-web-sg" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound traffic for the lab"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  count             = var.allow_public_http ? 1 : 0
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Public HTTP lab demo only"
}
