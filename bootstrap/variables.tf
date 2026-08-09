variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "aws-3tier"
}

variable "github_sub_prefix" {
  description = "깃헙 리포"
  type        = string
  default     = "repo:winterconquest@186372410/aws-3tier-infra@1306240315"
}