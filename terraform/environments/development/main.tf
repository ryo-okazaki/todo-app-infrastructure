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
