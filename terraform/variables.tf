# variables.tf
# 프로젝트 전반의 변수 정의

# ============================================
# 공통 설정
# ============================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "aws-3tier"
}

variable "environment" {
  description = "환경 구분"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "리소스를 배포할 AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# ============================================
# 네트워크
# ============================================

variable "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public Subnet의 CIDR 블록"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "App Subnet의 CIDR 블록"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "DB Subnet의 CIDR 블록"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "availability_zones" {
  description = "AZ 리스트"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# ============================================
# EC2
# ============================================

variable "ec2_instance_type" {
  description = "인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "ASG 최소 사이즈"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG 최대 사이즈"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "표준 크기"
  type        = number
  default     = 2
}

# ============================================
# RDS
# ============================================

variable "db_instance_class" {
  description = "RDS 인스턴스"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "DB 크기"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "DB 버전"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "DB 이름"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS 유저이름"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS 비밀번호"
  type        = string
  sensitive   = true
}

# ============================================
# CloudWatch
# ============================================

variable "alert_email" {
  description = "CloudWatch Endpoint E-mail"
  type        = string
  sensitive   = true
}

variable "db_free_storage_threshold_ratio" {
  description = "여유 공간 임계 비율 (기본 20%)"
  type        = number
  default     = 0.2
}