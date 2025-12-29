module "shared_secrets" {
  source = "../../modules/secrets"

  name                    = var.name_prefix
  recovery_window_in_days = 0 # Dev環境用。本番では 7-30 を推奨

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_port     = var.db_port

  db_host = module.database.db_address
}

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

  cloudfront_custom_header_name  = var.cloudfront_custom_header_name
  cloudfront_custom_header_value = module.shared_secrets.cloudfront_origin_secret_value
}

# ------------------------------------------------------------------------------
# CDN Module (ALB + CloudFront)
# ------------------------------------------------------------------------------
module "cdn_api" {
  source = "../../modules/cdn/api"

  name                = "todo-app-api"
  domain_name         = var.domain_name
  acm_certificate_arn = module.domain.acm_cloudfront_certificate_arn
  alb_domain_name     = module.load_balancer.alb_dns_name
  route53_zone_id     = module.domain.route53_zone_id

  origin_custom_header_name  = var.cloudfront_custom_header_name
  origin_custom_header_value = module.shared_secrets.cloudfront_origin_secret_value

  # Optional
  price_class = "PriceClass_200"
  enable_waf  = false
}

# ------------------------------------------------------------------------------
# CDN Module (S3 + CloudFront)
# ------------------------------------------------------------------------------
module "cdn_assets" {
  source = "../../modules/cdn/assets"

  environment   = var.environment
  force_destroy = true

  # Domain設定（domain moduleから取得）
  domain_name             = module.domain.domain_name
  static_assets_subdomain = "cdn"
  media_subdomain         = "media"

  # ACM証明書（domain moduleから取得）
  cloudfront_certificate_arn = module.domain.cloudfront_certificate_arn

  # Route53 Zone（domain moduleから取得）
  route53_zone_id = module.domain.zone_id

  # ログバケット（storage moduleから取得）
  logs_bucket_id = module.storage.logs_bucket.id

  # WAF設定
  enable_waf     = false
  waf_web_acl_id = null
}

# ==============================================================================
# Mail (SES)
# ==============================================================================
module "mail" {
  source = "../../modules/mail"

  domain_name = var.domain_name
  zone_id     = module.domain.zone_id

  # 個別メールアドレスの検証
  from_email_addresses = [
    "noreply@${var.domain_name}",
    "support@${var.domain_name}"
  ]

  # DKIM有効化
  enable_dkim = true

  # Configuration Set (送信トラッキング)
  enable_configuration_set = true
  configuration_set_name   = "${var.name_prefix}-config-set"

  # SNS通知 (開発環境では無効化も可)
  enable_sns_notifications = true
  sns_topic_name           = "${var.name_prefix}-ses-notifications"
}

