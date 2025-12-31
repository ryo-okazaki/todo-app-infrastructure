# ToDoアプリ インフラ

## 概要

このリポジトリは、ToDoアプリケーション（`todo-app-next` および `todo-app-express`）をAWS ECS上で動作させるためのインフラストラクチャをTerraformで管理します。

## 管理対象リソース

- **VPC**: ネットワーク基盤（パブリック/プライベートサブネット）
- **RDS (PostgreSQL)**: アプリケーション用データベース
- **ECS (Fargate)**: コンテナ実行環境
- **ALB**: ロードバランサー
- **CloudFront**: CDN（API配信、静的アセット配信、メディア配信）
- **S3**: ECRリポジトリ、ログ保存、静的アセット、メディアファイル
- **SES**: メール送信サービス
- **Secrets Manager**: 認証情報管理
- **Route53**: DNS管理

## 技術スタック

- **Terraform**: >= 1.3
- **AWS CLI**: >= v2.13

## 前提条件

### 必須ツール

- Terraform >= 1.3
- AWS CLI >= v2.13

### 必要な権限

- **PowerUser** 権限
- **Assume Role設定**: AWS DNSアカウントと各環境用のAWSアカウント間でのAssumeRole
  - 詳細は `scripts/create-tf-delegation-assume-role.sh` を参照

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd todo-app-infrastructure
```

### 2. Terraform Backend設定

Remote Backendを使用する場合、`{環境名}.tfbackend.sample` から `{環境名}.tfbackend` を作成してください。

```bash
cd terraform/environments/development
cp development.tfbackend.sample development.tfbackend
```

#### Backend設定パラメータ

| パラメータ | 説明 | 例 |
|----------|------|-----|
| `bucket` | Terraform State管理用S3バケット名 | `develop.todo-app.tf-state-bucket` |
| `key` | State ファイルのパス | `terraform.tfstate` |
| `region` | AWSリージョン | `ap-northeast-1` |
| `encrypt` | State ファイルの暗号化 | `true` |

### 3. 環境変数設定

`terraform.tfvars.sample` から `terraform.tfvars` を作成し、環境に応じた値を設定してください。

```bash
cd terraform/environments/development
cp terraform.tfvars.sample terraform.tfvars
```

#### 環境変数一覧

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `environment` | 環境名 | `development` |
| `vpc_cidr` | VPC CIDR ブロック | `10.0.0.0/16` |
| `availability_zones` | 使用するAZ | `["ap-northeast-1a", "ap-northeast-1c"]` |
| `public_subnet_cidrs` | パブリックサブネット CIDR | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | プライベートサブネット CIDR | `["10.0.10.0/24", "10.0.20.0/24"]` |
| `db_name` | データベース名 | `todo_app` |
| `db_username` | データベースユーザー名 | `todo_user` |
| `db_password` | データベースパスワード | `Password123!` |
| `db_port` | データベースポート | `5432` |
| `domain_name` | アプリケーションドメイン名 | `dev.todo-app.ryo-okazaki.com` |
| `parent_zone_id` | 親Route53ゾーンID | `Z015764518G1D049IWPT0` |
| `dns_account_assume_role` | DNS管理アカウントのAssumeRole ARN | `arn:aws:iam::xxxx:role/TerraformDNSDelegationRole` |
| `api_container_port` | APIコンテナポート | `3000` |
| `api_container_domain_suffix` | Service Connect用ドメインサフィックス | `service.internal` |
| `web_container_port` | Webコンテナポート | `3000` |
| `service_connect_dns_name` | Service ConnectのDNS名 | `backend` |
| `ecr_repositories` | ECRリポジトリ名リスト | `["backend", "frontend"]` |
| `ecr_repository_api` | APIコンテナ用ECRリポジトリ名 | `backend` |
| `ecr_repository_web` | Webコンテナ用ECRリポジトリ名 | `frontend` |
| `keycloak_client_url` | Keycloak認証サーバーURL | `https://dev.auth.ryo-okazaki.com` |
| `keycloak_api_client_id` | Keycloak API用クライアントID | `todo-backend-client` |
| `keycloak_web_client_id` | Keycloak Web用クライアントID | `todo-frontend-client` |
| `keycloak_realm` | Keycloak Realm名 | `common-auth-system` |

## デプロイ手順

### Development環境へのデプロイ

```bash
# 1. 初期化
make tf-init-dev

# 2. フォーマット確認
make tf-fmt-dev

# 3. バリデーション
make tf-vali-dev

# 4. プラン確認
make tf-plan-dev

# 5. 適用
make tf-apply-dev
```

### State確認

```bash
# State一覧表示
make tf-state-dev

# Output確認
make tf-out-dev
```

## State管理

Terraform StateはS3バケットで管理されます。`development.tfbackend` に設定したバケットとキーで管理されます。

## ディレクトリ構成

詳細は [ディレクトリ構成](./docs/dir/structure.md) を参照してください。

## 削除手順

**注意**: 以下のコマンドは全てのリソースを削除します。

```bash
make tf-destroy-dev
```

## 関連リポジトリ

- [todo-app-frontend](https://github.com/ryo-okazaki/todo-app-frontend): フロントエンド（Next.js）
- [todo-app-backend](https://github.com/ryo-okazaki/todo-app-backend): バックエンド（Express）
- [common-auth-system](https://github.com/ryo-okazaki/common-auth-system): 共通認証基盤（Keycloak）

## アーキテクチャ構成図

詳細は [docs/architecture/](./docs/architecture/) を参照してください。
