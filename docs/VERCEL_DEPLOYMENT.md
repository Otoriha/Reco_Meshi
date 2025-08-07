# Vercelデプロイ手順（Web版フロントエンド）

## 前提条件
- Vercelアカウントを作成済み
- GitHubリポジトリとの連携が完了している

## デプロイ手順

### 1. Vercelプロジェクトの作成

1. [Vercel Dashboard](https://vercel.com/dashboard) にアクセス
2. 「New Project」をクリック
3. GitHubリポジトリ「Otoriha/Reco_Meshi」を選択
4. プロジェクト名を設定（例：`reco-meshi-web`）

### 2. ビルド設定

以下の設定を行います：

| 設定項目 | 値 |
|---------|-----|
| Framework Preset | Vite |
| Root Directory | `frontend` |
| Build Command | `npm run build` |
| Output Directory | `dist` |
| Install Command | `npm install` |

### 3. 環境変数の設定

Vercelダッシュボードの「Settings」→「Environment Variables」で以下を設定：

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `VITE_API_URL` | バックエンドAPIのURL | `https://api.recomeshi.com/api/v1` |
| `VITE_APP_URL` | フロントエンドのURL | `https://recomeshi.com` |

**注意事項:**
- 本番環境のAPI URLは、バックエンドがデプロイされた後に設定してください
- 開発環境と本番環境で異なる値を設定する場合は、Environment（Production/Preview/Development）ごとに設定可能です

### 4. デプロイの実行

1. 「Deploy」ボタンをクリック
2. ビルドログを確認し、エラーがないことを確認
3. デプロイ完了後、提供されたURLでアプリケーションにアクセス

### 5. カスタムドメインの設定（オプション）

1. 「Settings」→「Domains」にアクセス
2. カスタムドメインを追加
3. DNSレコードを設定（Vercelが提供する指示に従う）

## 自動デプロイ

GitHubのmainブランチにマージされると自動的にデプロイが実行されます。

### ブランチプレビュー
- Pull Requestを作成すると、自動的にプレビューデプロイが作成されます
- PRのコメントにプレビューURLが自動的に追加されます

## トラブルシューティング

### ビルドエラーが発生した場合
1. ローカルで `npm run build` が成功することを確認
2. Node.jsのバージョンを確認（package.jsonにenginesフィールドを追加することを推奨）
3. 環境変数が正しく設定されているか確認

### 404エラーが発生する場合
- SPAのルーティングが正しく設定されているか確認
- Vercelは自動的にSPAのルーティングを処理しますが、問題がある場合は`vercel.json`でrewritesを設定

## ローカルでの確認

デプロイ前にローカルで本番ビルドを確認：

```bash
cd frontend
npm run build
npm run preview
```

## 関連ドキュメント
- [Vercel Documentation](https://vercel.com/docs)
- [Vite Deployment Guide](https://vitejs.dev/guide/static-deploy.html#vercel)