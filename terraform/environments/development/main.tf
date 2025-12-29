module "network" {
  source = "../../modules/network"

  name     = var.name_prefix
  vpc_cidr = var.vpc_cidr

  # 東京リージョンの 1a, 1c
  azs = var.availability_zones

  # subnet CIDR はAZごとに1つずつ指定
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  api_container_domain_suffix = var.api_container_domain_suffix
}

module "database" {
  source = "../../modules/database"

  name = var.name_prefix

  # networkモジュールのOutputを利用
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  # DB設定
  instance_class = "db.t3.micro" # 開発用なので最小
  multi_az       = false         # 開発用なのでSingle-AZ
  db_name        = var.db_name
  db_password    = var.db_password
  db_username    = var.db_username
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

module "storage" {
  source = "../../modules/storage"

  env              = var.environment
  name             = var.name_prefix
  force_destroy    = true # 開発環境なのでterraform destroyで消せるようにする
  ecr_repositories = var.ecr_repositories
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  name = var.name_prefix

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  # domainモジュールで作った証明書
  acm_certificate_arn = module.domain.alb_certificate_arn

  # storageモジュールで作ったログ用バケット
  access_logs_bucket_id = module.storage.logs_bucket.id
}
