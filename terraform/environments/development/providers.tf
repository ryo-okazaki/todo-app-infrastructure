provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dns_account"
  region = "ap-northeast-1" # Route53はGlobalだが指定が必要

  assume_role {
    # Step 1で作ったロールのARN
    role_arn = var.dns_account_assume_role
  }
}
