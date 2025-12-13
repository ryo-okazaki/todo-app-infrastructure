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
