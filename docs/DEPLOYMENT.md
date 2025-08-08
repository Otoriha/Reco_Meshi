# LIFF Vercel デプロイ手順

## 前提条件
- Vercelアカウントを作成済み
- LINE Developersアカウントを作成済み
- GitHubリポジトリへのアクセス権限

## 1. LINE Developersでの準備

### LIFFアプリの作成
1. [LINE Developers Console](https://developers.line.biz/)にログイン
2. プロバイダーを選択（または新規作成）
3. 「新規チャネル作成」→「LINEミニアプリ」を選択
4. 必要情報を入力：
   - チャネル名：レコめし LIFF
   - チャネル説明：食材管理アプリのLIFF版
5. LIFFタブから「LIFFアプリを追加」
6. 設定：
   - LIFFアプリ名：レコめし
   - サイズ：Full
   - エンドポイントURL：一旦 `https://example.com` を入力（後で更新）
7. 生成されたLIFF IDをメモ

## 2. Vercelでのデプロイ

### 初回デプロイ
1. [Vercel](https://vercel.com)にログイン
2. 「Add New Project」をクリック
3. GitHubリポジトリ「Reco_Meshi」をインポート
4. Configure Project：
   - **Framework Preset**: Vite
   - **Root Directory**: `liff` を指定（重要！）
   - **Build Command**: `npm run build`（自動検出される）
   - **Output Directory**: `dist`（自動検出される）

### 環境変数の設定
Environment Variablesセクションで以下を追加：

| Name | Value | 備考 |
|------|-------|------|
| `VITE_LIFF_ID` | LINE DevelopersのLIFF ID | 例：2000123456-AbCdEfGh |
| `VITE_API_URL` | バックエンドAPIのURL | 本番環境のURL |

### デプロイ実行
1. 「Deploy」ボタンをクリック
2. デプロイが完了するまで待機（約1-2分）
3. デプロイ完了後、URLが発行される
   - 例：`https://reco-meshi-liff.vercel.app`

## 3. LINE Developersの設定更新

1. LINE Developers Consoleに戻る
2. LIFFアプリの設定を開く
3. エンドポイントURLをVercelのURLに更新
   - 例：`https://reco-meshi-liff.vercel.app`
4. 「更新」をクリック

## 4. 動作確認

### LIFFアプリの起動確認
1. LINE Developersコンソールから「LIFF URL」をコピー
   - 形式：`https://liff.line.me/{LIFF_ID}`
2. スマートフォンのLINEアプリでURLを開く
3. LIFFアプリが正常に起動することを確認

### デバッグ方法
- PCブラウザで確認する場合：
  1. LIFF URLに `?liff.state=/` を追加
  2. 例：`https://liff.line.me/{LIFF_ID}?liff.state=/`
- Vercelのログ確認：
  - Vercelダッシュボード → Functions → Logs

## 5. 継続的デプロイ

GitHubのmainブランチにマージされると自動的にデプロイされます。

### ブランチプレビュー
- PR作成時、Vercelが自動的にプレビューURLを生成
- PRのコメントにプレビューURLが追加される
- マージ前の動作確認が可能

## 6. カスタムドメイン（オプション）

独自ドメインを使用する場合：
1. Vercelダッシュボード → Settings → Domains
2. カスタムドメインを追加
3. DNSレコードを設定
4. LINE DevelopersのエンドポイントURLを更新

## トラブルシューティング

### LIFFが起動しない
- LIFF IDが正しく設定されているか確認
- エンドポイントURLがHTTPSであることを確認
- Vercelの環境変数が正しく設定されているか確認

### 環境変数が読み込まれない
- 変数名が`VITE_`で始まっているか確認
- Vercelで再デプロイを実行

### ビルドエラー
- `liff`ディレクトリがRoot Directoryに設定されているか確認
- package.jsonの依存関係を確認

## 関連ドキュメント
- [Vercel Documentation](https://vercel.com/docs)
- [LINE LIFF Documentation](https://developers.line.biz/ja/docs/liff/)
- [Vite Deployment Guide](https://vitejs.dev/guide/static-deploy.html#vercel)