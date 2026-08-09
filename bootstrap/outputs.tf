output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}