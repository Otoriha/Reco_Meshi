# Fly.io デプロイ手順

## 前提条件
- Fly.ioアカウントの作成
- Fly CLIのインストール: `brew install flyctl` (Mac) または https://fly.io/docs/flyctl/install/

## 初回セットアップ

### 1. Fly.ioにログイン
```bash
fly auth login
```

### 2. アプリケーションの作成
```bash
fly launch --no-deploy
```
※ 対話形式で以下を設定:
- アプリ名: reco-meshi (fly.tomlで設定済み)
- リージョン: nrt (東京)
- PostgreSQLデータベース: 作成する
- Redisデータベース: 作成する

### 3. 環境変数の設定
```bash
# Rails master key
fly secrets set RAILS_MASTER_KEY=<your_actual_master_key>

# LINE API関連
fly secrets set LINE_CHANNEL_SECRET=<your_line_channel_secret>
fly secrets set LINE_CHANNEL_ACCESS_TOKEN=<your_line_channel_access_token>
fly secrets set LIFF_ID=<your_liff_id>

# Google Cloud関連
fly secrets set GOOGLE_CLOUD_PROJECT_ID=<your_project_id>
fly secrets set GOOGLE_CLOUD_CREDENTIALS=<base64_encoded_credentials>

# AI API Keys
fly secrets set OPENAI_API_KEY=<your_openai_api_key>
fly secrets set GEMINI_API_KEY=<your_gemini_api_key>

# Redis URL (Fly.io Redisを使用する場合)
fly secrets set REDIS_URL=<redis_connection_url>
fly secrets set SIDEKIQ_REDIS_URL=<redis_connection_url>

# CORS設定（フロントエンドのURLを設定）
fly secrets set FRONTEND_URL=<your_frontend_url>
fly secrets set LIFF_URL=<your_liff_url>
```

### 4. データベースの確認
```bash
# PostgreSQL接続情報の確認
fly postgres attach --app reco-meshi

# DATABASE_URLが自動で設定されることを確認
fly secrets list
```

## デプロイ

### 初回デプロイ
```bash
fly deploy
```

### 更新時のデプロイ
```bash
# コードの変更をコミット
git add .
git commit -m "Update for deployment"

# デプロイ実行
fly deploy
```

## 運用管理

### ログの確認
```bash
# リアルタイムログ
fly logs

# 過去のログ
fly logs --since 1h
```

### アプリケーションの状態確認
```bash
fly status
```

### SSHでコンテナに接続
```bash
fly ssh console
```

### Railsコンソールの起動
```bash
fly ssh console -C "/rails/bin/rails console"
```

### データベースマイグレーション（手動実行）
```bash
fly ssh console -C "/rails/bin/rails db:migrate"
```

### スケーリング
```bash
# インスタンス数の変更
fly scale count 2

# マシンサイズの変更
fly scale vm shared-cpu-2x --memory 1024
```

### アプリケーションの停止/開始
```bash
# 停止
fly scale count 0

# 開始
fly scale count 1
```

## トラブルシューティング

### デプロイが失敗する場合
1. ログを確認: `fly logs`
2. ビルドログを確認: `fly deploy --verbose`
3. シークレットが正しく設定されているか確認: `fly secrets list`

### データベース接続エラー
1. DATABASE_URLが設定されているか確認: `fly secrets list | grep DATABASE_URL`
2. PostgreSQLが正しくアタッチされているか確認: `fly postgres list`

### メモリ不足エラー
```bash
# メモリを増やす
fly scale memory 1024
```

## 本番環境URL
デプロイ後、以下のURLでアクセス可能:
- https://reco-meshi.fly.dev

## 注意事項
- master keyは絶対に公開しないこと
- 環境変数の値は実際の値に置き換えること
- 定期的にバックアップを取ること
- Fly.ioの無料枠の制限に注意（2024年時点で3つのVMまで無料）
- フロントエンド（Web版、LIFF版）は別途デプロイが必要
- CORS設定でフロントエンドのURLを必ず設定すること