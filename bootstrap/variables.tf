variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "aws-3tier"
}

variable "aws_region" {
  description = "리소스를 배포할 AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "github_sub_prefix" {
  description = "깃헙 리포"
  type        = string
  default     = "repo:winterconquest@186372410/aws-3tier-infra@1306240315"
}