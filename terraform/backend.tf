terraform {
  backend "s3" {
    bucket       = "aws-3tier-tfstate-703440311746"
    key          = "3tier/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
    encrypt      = true
  }
}