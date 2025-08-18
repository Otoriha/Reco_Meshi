# LINE Bot 本番環境セットアップガイド

## 概要

このドキュメントでは、レコめしのLINE Bot機能を本番環境で利用するためのセットアップ手順を説明します。

## 前提条件

- LINE Developersアカウントが作成済み
- Messaging APIチャネルが作成済み
- 本番環境（Fly.io等）がデプロイ済み

## 1. LINE Developersコンソールでの設定

### 1.1 Webhook URL設定

1. [LINE Developers](https://developers.line.biz/console/)にログイン
2. 対象のプロバイダーとチャネルを選択
3. 「Messaging API設定」タブを開く
4. 「Webhook設定」セクションで以下を設定：
   - **Webhook URL**: `https://your-domain.com/api/v1/line/webhook`
   - **Webhookの利用**: ON
   - **Webhook再送**: ON（推奨）

### 1.2 チャネルアクセストークン

1. 「Messaging API設定」タブの「チャネルアクセストークン」セクション
2. 「発行」ボタンをクリックしてトークンを生成
3. 生成されたトークンをコピーして保存

### 1.3 チャネルシークレット

1. 「チャネル基本設定」タブを開く
2. 「チャネルシークレット」をコピーして保存

## 2. 環境変数の設定

本番環境に以下の環境変数を設定してください：

```bash
# LINE Bot設定
LINE_CHANNEL_SECRET=your_channel_secret_here
LINE_CHANNEL_ACCESS_TOKEN=your_channel_access_token_here
LIFF_ID=your_liff_id_here

# フロントエンド URL
FRONTEND_URL=https://your-frontend-domain.com
LIFF_URL=https://your-liff-domain.com
```

### Fly.ioでの設定例

```bash
fly secrets set LINE_CHANNEL_SECRET=your_channel_secret_here
fly secrets set LINE_CHANNEL_ACCESS_TOKEN=your_channel_access_token_here
fly secrets set LIFF_ID=your_liff_id_here
fly secrets set FRONTEND_URL=https://reco-meshiweb.vercel.app
fly secrets set LIFF_URL=https://reco-meshi.vercel.app
```

## 3. リッチメニューの設定

### 3.1 リッチメニューの作成

```bash
# Dockerコンテナ内で実行
docker-compose exec backend rails line:setup_rich_menu
```

### 3.2 設定確認

```bash
# 設定状況の確認
docker-compose exec backend rails line:show_config

# リッチメニュー一覧の確認
docker-compose exec backend rails line:list_rich_menus

# デフォルトリッチメニューの確認
docker-compose exec backend rails line:get_default_rich_menu
```

## 4. 動作確認

### 4.1 接続テスト

```bash
# LINE Bot接続テスト
docker-compose exec backend rails line:test_connection
```

### 4.2 Webhook動作確認

1. LINE公式アカウントを友だち追加
2. 以下のメッセージを送信して動作確認：
   - 「こんにちは」→ 挨拶メッセージが返信される
   - 「ヘルプ」→ ヘルプメニューが表示される
   - 画像を送信 → 画像受信メッセージが返信される

### 4.3 リッチメニュー確認

- リッチメニューが表示されることを確認
- 各ボタンが正常に動作することを確認

## 5. トラブルシューティング

### 5.1 Webhookが動作しない場合

1. **Webhook URLが正しく設定されているか確認**
   ```
   https://your-domain.com/api/v1/line/webhook
   ```

2. **SSL証明書が有効か確認**
   - LINEはHTTPS必須です

3. **ログの確認**
   ```bash
   # アプリケーションログ
   docker-compose logs backend
   
   # Railsログ
   docker-compose exec backend tail -f log/production.log
   ```

### 5.2 認証エラーの場合

1. **環境変数の確認**
   ```bash
   docker-compose exec backend rails line:show_config
   ```

2. **チャネルシークレット・アクセストークンの再確認**
   - LINE Developersコンソールで正しい値をコピーしているか確認

### 5.3 リッチメニューが表示されない場合

1. **リッチメニューの設定状況確認**
   ```bash
   docker-compose exec backend rails line:list_rich_menus
   docker-compose exec backend rails line:get_default_rich_menu
   ```

2. **リッチメニューの再設定**
   ```bash
   # 既存メニューを削除して再作成
   docker-compose exec backend rails line:cleanup_rich_menus
   docker-compose exec backend rails line:setup_rich_menu
   ```

## 6. メンテナンスコマンド

### 6.1 リッチメニュー管理

```bash
# 全リッチメニューの削除
docker-compose exec backend rails line:cleanup_rich_menus

# デフォルトリッチメニューの解除
docker-compose exec backend rails line:cancel_default_rich_menu

# リッチメニューの再設定
docker-compose exec backend rails line:setup_rich_menu
```

### 6.2 設定確認

```bash
# LINE Bot設定の表示
docker-compose exec backend rails line:show_config

# 接続テスト
docker-compose exec backend rails line:test_connection
```

## 7. セキュリティ考慮事項

### 7.1 環境変数の管理

- チャネルシークレットとアクセストークンは絶対に公開しない
- 本番環境では環境変数またはシークレット管理サービスを使用
- 定期的なトークンローテーションを検討

### 7.2 Webhook検証

- すべてのWebhookリクエストで署名検証を実施
- 不正なリクエストは適切にログ出力とエラーハンドリング

### 7.3 レート制限

- LINE Messaging APIのレート制限に注意
- 大量のメッセージ送信時は適切な間隔を空ける

## 8. 監視・運用

### 8.1 ログ監視

以下のイベントを監視することを推奨：

- Webhook受信エラー
- LINE API呼び出しエラー
- 署名検証失敗
- 予期しないメッセージタイプ

### 8.2 メトリクス

- メッセージ受信数
- メッセージ送信数
- エラー率
- レスポンス時間

## 9. 今後の拡張

### 9.1 画像認識機能の追加

- Google Cloud Vision APIとの連携
- Sidekiqジョブでの非同期画像処理

### 9.2 AI機能の追加

- OpenAI/Gemini APIとの連携
- レシピ提案機能の実装

### 9.3 ユーザー管理

- LINE ID とアプリユーザーの紐付け
- ユーザー設定の管理

## サポート

問題が発生した場合は、以下の情報と共にサポートにお問い合わせください：

- エラーメッセージ
- 再現手順
- 環境設定（機密情報を除く）
- ログファイル（機密情報を除く）