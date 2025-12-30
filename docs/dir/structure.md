# ディレクトリ構成

```
todo-app-infrastructure/
├── terraform/
│   ├── environments/          # 環境ごとの設定
│   │   ├── development/       # 開発環境
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── providers.tf
│   │   │   ├── backend.tf
│   │   │   ├── terraform.tfvars        # 環境変数（gitignore対象）
│   │   │   ├── terraform.tfvars.sample # サンプル
│   │   │   ├── development.tfbackend   # Backend設定（gitignore対象）
│   │   │   └── development.tfbackend.sample # サンプル
│   │   ├── staging/           # ステージング環境
│   │   └── production/        # 本番環境
│   │
│   └── modules/               # 再利用可能なモジュール
│       ├── network/           # VPC、サブネット、Service Discovery
│       ├── database/          # RDS (PostgreSQL)
│       ├── domain/            # Route53、ACM証明書
│       ├── storage/           # S3、ECR
│       ├── load_balancer/     # ALB
│       ├── cdn/               # CloudFront
│       │   ├── api/           # API用CDN (ALB origin)
│       │   └── assets/        # 静的アセット用CDN (S3 origin)
│       ├── mail/              # SES
│       ├── cluster/           # ECS Cluster
│       ├── secrets/           # Secrets Manager
│       └── services/          # ECSサービス
│           ├── api/           # バックエンド (Express)
│           └── web/           # フロントエンド (Next.js)
│
├── scripts/                   # 便利スクリプト
│   └── create-tf-delegation-assume-role.sh
│
├── docs/                      # ドキュメント
│   ├── architecture/          # アーキテクチャ図
│   └── dir/                   # ディレクトリ構成説明
│
├── Makefile                   # タスクランナー
└── README.md                  # プロジェクト説明
```

## 主要ディレクトリの説明

### `terraform/environments/`

環境ごと（development、staging、production）の設定を管理します。各環境は独立したTerraform Stateを持ち、異なる設定値（インスタンスサイズ、AZ等）を使用できます。

### `terraform/modules/`

再利用可能なTerraformモジュールを格納します。各モジュールは特定のAWSリソースセットを管理し、environments配下から呼び出されます。

#### 主要モジュール

- **network**: VPC、パブリック/プライベートサブネット、Service Discovery Namespace
- **database**: RDS PostgreSQL、セキュリティグループ、サブネットグループ
- **domain**: Route53ホストゾーン、ACM証明書（CloudFront用とALB用）
- **storage**: S3バケット（ログ、静的アセット、メディア）、ECRリポジトリ
- **load_balancer**: Application Load Balancer、ターゲットグループ、リスナー
- **cdn/api**: CloudFront（API配信、ALB origin）
- **cdn/assets**: CloudFront（静的アセット・メディア配信、S3 origin）
- **mail**: Amazon SES（メール送信、ドメイン検証、DKIM）
- **cluster**: ECS Cluster、Container Insights設定
- **secrets**: Secrets Manager（DB認証情報、JWT Secret等）
- **services/api**: ECS Service（Expressバックエンド）
- **services/web**: ECS Service（Next.jsフロントエンド）

### `scripts/`

インフラ管理に必要なスクリプトを格納します。

- `create-tf-delegation-assume-role.sh`: DNS管理アカウントとのAssumeRole設定スクリプト

### `docs/`

プロジェクトのドキュメントを格納します。

- `architecture/`: システムアーキテクチャ図
- `dir/`: ディレクトリ構成説明（本ドキュメント）

## Terraform State管理

各環境のStateは、S3バケットでリモート管理されます。`{環境名}.tfbackend` ファイルでバケット名やキーを指定します。
