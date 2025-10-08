# セキュリティ診断 クイックリファレンス

**対象**: Reco Meshi (レコめし)  
**診断日**: 2025年10月8日

---

## 📊 診断結果サマリー

| 重大度 | 件数 | 期限 | 推定工数 |
|--------|------|------|----------|
| 🔴 **CRITICAL** | 3 | 即時 | 4時間 |
| 🟠 **HIGH** | 8 | 1週間以内 | 16時間 |
| 🟡 **MEDIUM** | 7 | 1ヶ月以内 | 20時間 |
| 🟢 **LOW** | 3 | 2ヶ月以内 | 2時間 |
| **合計** | **21** | - | **42時間** |

---

## 🚨 即時対応必須（CRITICAL）

### 1. Sidekiq Web UI の認証不備
**リスク**: 管理画面への無認証アクセス、機密情報漏洩  
**対策**: Basic認証の追加  
```ruby
# backend/config/routes.rb
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  # 認証ロジック
end
```
**作業時間**: 1時間  
**担当**: シニアエンジニア

---

### 2. Nonce検証のバイパス
**リスク**: CSRF攻撃、アカウント乗っ取り  
**対策**: nonce を必須化  
```ruby
# backend/app/services/line_auth_service.rb
raise AuthenticationError, "Nonce is required" if nonce.blank?
```
**作業時間**: 2時間  
**担当**: シニアエンジニア

---

### 3. Gemini APIキーがURLに露出
**リスク**: APIキー漏洩、不正利用による課金  
**対策**: ヘッダーでAPIキーを送信  
```ruby
# backend/app/services/llm/gemini_service.rb
f.headers['x-goog-api-key'] = @api_key
resp = @conn.post(path, body)  # クエリパラメータなし
```
**作業時間**: 1時間  
**担当**: バックエンドエンジニア

---

## 🔥 高優先度（HIGH - 1週間以内）

| # | 脆弱性 | 影響 | 工数 |
|---|--------|------|------|
| 4 | JWT有効期限が長い(1日) | トークン盗取時の被害拡大 | 3h |
| 5 | JWT秘密鍵のフォールバック | 鍵管理の不適切 | 1h |
| 6 | IDOR (認可チェック不備) | 他ユーザーデータアクセス | 4h |
| 7 | パスワード最小長6文字 | ブルートフォース攻撃 | 2h |
| 8 | SQL Injection の可能性 | データベース侵害 | 2h |
| 9 | APIキー必須化の不備 | キー未設定での起動 | 1h |
| 10 | localStorage に JWT保存 | XSS 時のトークン漏洩 | 3h |
| 11 | ホスト検証が無効 | DNS Rebinding 攻撃 | 1h |

**合計**: 16時間

---

## ⚠️ 中優先度（MEDIUM - 1ヶ月以内）

- レート制限の実装 (Rack::Attack)
- 画像ファイル検証の強化
- CORS設定の見直し
- ログフィルタリングの強化
- Vision API 呼び出し制限
- LLM プロンプトインジェクション対策
- Sidekiq リトライ設定
- Webhook 署名検証ログ改善

**合計**: 20時間

---

## ✅ 低優先度（LOW - 2ヶ月以内）

- CORS Preflight ヘッダー制限
- 全環境での HTTPS 強制
- セキュリティヘッダーの追加

**合計**: 2時間

---

## 📋 即時対応チェックリスト

### Day 1: CRITICAL 対応
- [ ] Sidekiq Web UI に Basic認証を追加
  - [ ] `backend/config/routes.rb` を修正
  - [ ] 環境変数 `SIDEKIQ_USERNAME`, `SIDEKIQ_PASSWORD` を設定
  - [ ] ローカルでテスト
  
- [ ] Nonce検証を必須化
  - [ ] `backend/app/services/line_auth_service.rb` を修正
  - [ ] `backend/app/controllers/api/v1/auth/line_auth_controller.rb` を修正
  - [ ] RSpec テスト追加
  
- [ ] Gemini APIキーをヘッダーに移動
  - [ ] `backend/app/services/llm/gemini_service.rb` を修正
  - [ ] WebMock テスト追加

- [ ] PR作成・レビュー
- [ ] 本番デプロイ

### Day 2-5: HIGH 対応
- [ ] JWT有効期限を短縮 (15分 + リフレッシュトークン)
- [ ] JWT秘密鍵を独立した環境変数に
- [ ] IDOR対策（全コントローラー）
  - [ ] `user_ingredients_controller.rb`
  - [ ] `shopping_lists_controller.rb`
  - [ ] `recipe_histories_controller.rb`
  - [ ] `favorite_recipes_controller.rb`
- [ ] パスワード強度要件を12文字以上に
- [ ] Arel.sql の安全な書き換え
- [ ] APIキーの必須化
- [ ] localStorage → HttpOnly Cookie
- [ ] ホスト検証の有効化

### Week 2-4: MEDIUM 対応
- [ ] Rack::Attack でレート制限実装
- [ ] 画像ファイルの内容検証（MiniMagick）
- [ ] CORS設定を環境変数で制御
- [ ] ログフィルタリング強化
- [ ] Vision API 呼び出し制限を厳格化
- [ ] LLM プロンプトサニタイズ
- [ ] Sidekiq リトライ設定最適化
- [ ] Webhook ログ改善

---

## 🛠️ 必要なツール・Gem

### 追加推奨 Gem
```ruby
# Gemfile
gem 'rack-attack'  # レート制限
gem 'bundler-audit', require: false  # 依存関係スキャン
gem 'brakeman', require: false  # 静的解析
```

### CI/CD 統合
```yaml
# .github/workflows/security.yml を追加
- Brakeman (静的解析)
- bundler-audit (依存関係)
- npm audit (フロントエンド)
- RuboCop Security
- TruffleHog (シークレットスキャン)
```

---

## 📞 緊急連絡先

| 役割 | 連絡先 |
|------|--------|
| セキュリティ責任者 | security@recomeshi.com |
| CTO | cto@recomeshi.com |
| 開発リード | dev@recomeshi.com |
| 法務 | legal@recomeshi.com |

---

## 📚 関連ドキュメント

- **詳細レポート**: `SECURITY_ASSESSMENT_REPORT.md`
- **修正パッチ**: `SECURITY_FIXES_CRITICAL.md`
- **CI設定**: `.github/workflows/security.yml`

---

## 🎯 今週の目標

### 最優先（今日中）
1. ✅ Sidekiq Web UI に認証追加
2. ✅ Nonce検証を必須化
3. ✅ Gemini APIキー修正

### 今週中
4. JWT有効期限短縮
5. IDOR対策（全コントローラー）
6. パスワード強度要件強化

### 来週以降
- レート制限実装
- セキュリティ監視ダッシュボード構築

---

## ⚡ クイックコマンド

### セキュリティスキャン実行
```bash
# バックエンド
cd backend
bundle exec brakeman --no-pager
bundle audit check --update

# フロントエンド
cd frontend
npm audit --audit-level=moderate

cd ../liff
npm audit --audit-level=moderate
```

### テスト実行
```bash
cd backend
bundle exec rspec spec/services/line_auth_service_spec.rb
bundle exec rspec spec/controllers/api/v1/
```

### ログ確認（機密情報漏洩チェック）
```bash
cd backend
grep -r "api_key\|secret\|password" log/ --color
```

---

## 💡 ベストプラクティス

### ✅ 実装済み（Good!）
- ✅ パスワードハッシュ化（bcrypt）
- ✅ HTTPS強制（production）
- ✅ JWT リボケーション
- ✅ LINE Webhook 署名検証
- ✅ SQL Injection 対策（ActiveRecord）

### ❌ 要改善
- ❌ レート制限なし
- ❌ localStorage に JWT
- ❌ ログに機密情報
- ❌ Nonce検証スキップ可能
- ❌ IDOR 脆弱性

---

## 📈 セキュリティスコア

**現在**: 52/100 (改善が必要)

| 項目 | スコア | 状態 |
|------|--------|------|
| 認証・認可 | 60/100 | 🟡 |
| 入力検証 | 70/100 | 🟡 |
| データ保護 | 40/100 | 🔴 |
| API セキュリティ | 50/100 | 🟠 |
| インフラ | 60/100 | 🟡 |

**目標**: 85/100 以上

**改善後の予測スコア**: 85/100 ✨

---

## 🔄 週次タスク（継続的改善）

### 毎週月曜日
- [ ] セキュリティログレビュー
- [ ] 依存関係アップデート確認
- [ ] 脆弱性スキャン実行

### 毎月1日
- [ ] セキュリティパッチ適用
- [ ] インシデントレポート確認
- [ ] アクセスログ分析

### 四半期ごと
- [ ] 脅威モデルの見直し
- [ ] ペネトレーションテスト
- [ ] セキュリティ研修実施

---

**最終更新**: 2025年10月8日  
**次回レビュー**: 2025年11月8日

---

## 🚀 さあ、始めましょう！

1. まず `SECURITY_FIXES_CRITICAL.md` を開く
2. CRITICAL 3件の修正を適用
3. テストを実行
4. PR作成・レビュー
5. 本番デプロイ

**所要時間**: 約4時間  
**期待効果**: 最も重大な脆弱性を即座に解消 🛡️

---

## 質問・サポート

わからないことがあれば、以下を参照してください：

- 詳細な修正方法: `SECURITY_FIXES_CRITICAL.md`
- 全脆弱性リスト: `SECURITY_ASSESSMENT_REPORT.md`
- CI設定: `.github/workflows/security.yml`

または、セキュリティチーム (security@recomeshi.com) にお問い合わせください。
