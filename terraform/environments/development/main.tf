module "network" {
  source = "../../modules/network"

  name     = "todo-app-dev"
  vpc_cidr = "10.0.0.0/16"

  # 東京リージョンの 1a, 1c
  azs = ["ap-northeast-1a", "ap-northeast-1c"]

  # subnet CIDR はAZごとに1つずつ指定
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
}

module "database" {
  source = "../../modules/database"

  name = "todo-app-dev"

  # networkモジュールのOutputを利用
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  # DB設定
  instance_class = "db.t3.micro"   # 開発用なので最小
  multi_az       = false           # 開発用なのでSingle-AZ
  db_password    = var.db_password # 変数から渡す
}

module "storage" {
  source = "../../modules/storage"

  name          = "develop.${data.aws_caller_identity.current.account_id}.todo-app"
  force_destroy = true # 開発環境なのでterraform destroyで消せるようにする
}

module "domain" {
  source = "../../modules/domain"

  domain_name    = var.domain_name
  parent_zone_id = var.parent_zone_id # ドメイン管理アカウントにある親ゾーンID

  providers = {
    aws             = aws
    aws.virginia    = aws.virginia
    aws.dns_account = aws.dns_account # 追加
  }
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  name = "todo-app-dev"

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  # domainモジュールで作った証明書
  acm_certificate_arn = module.domain.alb_certificate_arn

  # storageモジュールで作ったログ用バケット
  access_logs_bucket_id = module.storage.s3_logs_bucket_id
}

resource "aws_route53_record" "alias" {
  zone_id = module.domain.zone_id # domainモジュールのOutput
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.load_balancer.alb_dns_name
    zone_id                = module.load_balancer.alb_zone_id
    evaluate_target_health = true
  }
}
