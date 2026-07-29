# outputs.tf
# 주요 리소스 출력값 정의
# ALB DNS, CloudFront URL, RDS 엔드포인트 등

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id

}

output "public_subnets_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id

}

output "app_subnets_ids" {
  description = "App subnet IDs"
  value       = aws_subnet.app[*].id

}

output "db_subnets_ids" {
  description = "DB subnet IDs"
  value       = aws_subnet.db[*].id

}

output "cloudfront_url" {
  description = "CloudFront 접속 URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"

}

output "alb_dns_name" {
  description = "ALB의 DNS 이름"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}