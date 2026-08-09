#oicd.tf
#OIDC provider + 배포용 role

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "aws-3tier-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = ["sts.amazonaws.com"]
          "token.actions.githubusercontent.com:sub" = [
            "${var.github_sub_prefix}:pull_request",          #PR에서 plan 자동 실행
            "${var.github_sub_prefix}:environment:production" #Environmnet는 리포 설정에서 보호 규칙을 걸 수 있음. IAM 조건과 GitHub 승인 절차 연결
          ]
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_actions" {
  name        = "aws-3tier-github-actions-policy"
  description = "GitHub Actions에서 3-tier 인프라를 배포하기 위한 권한"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InfrastructureManagement"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "rds:*",
          "cloudfront:*",
          "cloudwatch:*",
          "sns:*",
          "ssm:*",
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole",
          "iam:TagInstanceProfile", "iam:UntagInstanceProfile", "iam:UntagRole",
          "iam:ListInstanceProfileTags", "iam:ListRoleTags",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles", "iam:GetRolePolicy",
          "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
          "iam:ListRolePolicies", "iam:ListInstanceProfilesForRole"
          # ... 나머지
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRoleToEC2"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}