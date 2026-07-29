# security_groups.tf
# ALB, EC2, RDS 보안 그룹 및 인바운드/아웃바운드 규칙

# ============================================
# ALB SG
# ============================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg-alb"
  }

}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = {
    Name = "${var.project_name}-alb-ingress-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${var.project_name}-alb-egress-all"
  }

}

# ============================================
# EC2 SG
# ============================================

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }

}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id = aws_security_group.ec2.id

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = {
    Name = "${var.project_name}-ec2-ingress-alb"
  }

}

resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${var.project_name}-ec2-egress-all"
  }

}

# ============================================
# RDS SG
# ============================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg-rds"
  }

}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"

  tags = {
    Name = "${var.project_name}-rds-ingress-ec2"
  }

}
