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
