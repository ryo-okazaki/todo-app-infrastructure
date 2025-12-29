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

# ==============================================================================
# ECS Cluster
# ==============================================================================
module "ecs_cluster" {
  source = "../../modules/cluster"

  env                       = var.environment
  name                      = "${var.name_prefix}-cluster"
  enable_container_insights = true

}

# ==============================================================================
# API Service (Express)
# ==============================================================================
module "api_service" {
  source = "../../modules/services/api"

  env        = var.environment
  name       = "${var.name_prefix}-backend"
  cluster_id = module.ecs_cluster.cluster_id

  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  # Service Connect設定
  service_connect_namespace_arn = module.network.service_discovery_namespace_arn
  service_connect_dns_name      = var.service_connect_dns_name

  # Container設定
  ecr_repository_url = module.storage.ecr_repositories[var.ecr_repository_api]
  container_port     = var.api_container_port
  cpu                = 256
  memory             = 512
  desired_count      = 1

  node_env = "development"

  secrets_arns = [
    module.shared_secrets.db_credentials_secret_arn,
    module.shared_secrets.database_url_secret_arn,
    module.shared_secrets.api_jwt_secret_arn,
  ]

  environment_variables = {
    SERVICE_CONNECT_DNS_NAME    = var.service_connect_dns_name
    API_CONTAINER_DOMAIN_SUFFIX = var.api_container_domain_suffix
    FRONTEND_BASE_URL           = "https://${var.domain_name}"
    S3_BUCKET                   = module.cdn_assets.media_bucket.id
    CLOUDFRONT_URL              = module.cdn_assets.media_cloudfront.url
    MAIL_FROM                   = "noreply@${var.domain_name}"
    MAIL_FROM_NAME              = "Todo App Support"
    PORT                        = tostring(var.api_container_port)
    NODE_ENV                    = "development"
  }

  secret_environment_variables = {
    DATABASE_URL               = module.shared_secrets.database_url_secret_arn
    JWT_SECRET                 = module.shared_secrets.api_jwt_secret_arn
    KEYCLOAK_BACKEND_CLIENT_ID = var.keycloak_api_client_id
    KEYCLOAK_REALM             = var.keycloak_realm
  }

  health_check_path = "/health"
}

# ==============================================================================
# Web Service (Next.js)
# ==============================================================================
module "ecs_frontend" {
  source = "../../modules/services/web"

  env        = var.environment
  name       = "${var.name_prefix}-frontend"
  cluster_id = module.ecs_cluster.cluster_id

  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  # ALB設定
  alb_security_group_id  = module.load_balancer.security_group_id
  https_listener_arn     = module.load_balancer.https_listener_arn
  listener_rule_priority = 10
  path_pattern           = ["/*"]

  # Service Connect設定
  service_connect_namespace_arn = module.network.service_discovery_namespace_arn

  # Container設定
  ecr_repository_url = module.storage.ecr_repositories[var.ecr_repository_web]
  container_port     = var.web_container_port
  cpu                = 512
  memory             = 1024
  desired_count      = 1

  environment_variables = {
    API_BASE_URL        = "http://${var.service_connect_dns_name}.${var.api_container_domain_suffix}:${var.api_container_port}"
    KEYCLOAK_CLIENT_URL = var.keycloak_client_url
    NODE_ENV            = "development"
  }

  secret_environment_variables = {
    JWT_SECRET                  = module.shared_secrets.api_jwt_secret_arn
    KEYCLOAK_FRONTEND_CLIENT_ID = var.keycloak_web_client_id
    KEYCLOAK_REALM              = var.keycloak_realm
  }

  health_check_path    = "/login"
  health_check_matcher = "200"
}
