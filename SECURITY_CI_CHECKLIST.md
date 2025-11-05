# CI/CDに組み込むセキュリティチェックリスト

このドキュメントでは、継続的にセキュリティを維持するためのCI/CDパイプライン設定を説明します。

---

## 📦 必要なツールのインストール

### Backend (Rails)

```ruby
# Gemfile に追加
group :development, :test do
  gem 'brakeman', require: false         # 静的セキュリティ分析
  gem 'bundler-audit', require: false    # 依存関係の脆弱性スキャン
  gem 'rubocop-rails-omakase'            # コード品質（既存）
end

# Production でも使用する可能性があるもの
gem 'rack-attack'  # レート制限
```

インストール:
```bash
cd backend
bundle install
```

### Frontend/LIFF (React)

```bash
cd frontend
npm install --save-dev npm-audit-ci-wrapper

cd ../liff  
npm install --save-dev npm-audit-ci-wrapper
```

---

## 🔧 ローカル開発での使用方法

### 1. Brakeman (Rails 静的解析)

```bash
cd backend

# 基本的なスキャン
bundle exec brakeman

# 詳細レポート（JSON形式）
bundle exec brakeman --format json --output brakeman-report.json

# 特定の深刻度以上のみ表示
bundle exec brakeman --severity-level 3  # High以上

# 出力例:
# +SECURITY WARNINGS+
# 
# High: 1
# Medium: 3
# Low: 2
```

**推奨**: コミット前に実行

---

### 2. Bundler Audit (依存関係の脆弱性)

```bash
cd backend

# データベース更新
bundle audit update

# 脆弱性チェック
bundle audit check

# 詳細モード
bundle audit check --verbose

# 出力例:
# Name: devise
# Version: 4.8.0
# Advisory: CVE-2023-XXXXX
# Criticality: High
# URL: https://github.com/advisories/...
# Solution: upgrade to >= 4.9.2
```

**推奨**: 毎週実行、依存関係更新時

---

### 3. RuboCop Security

```bash
cd backend

# セキュリティチェックのみ
bundle exec rubocop --only Security

# 自動修正可能なものは修正
bundle exec rubocop --only Security --auto-correct

# 出力例:
# app/controllers/api/v1/users_controller.rb:45:5: C: Security/Eval: 
# The use of eval is a serious security risk.
```

**推奨**: コミット前に実行

---

### 4. npm audit (フロントエンド)

```bash
cd frontend

# 脆弱性スキャン
npm audit

# 中程度以上の脆弱性のみ
npm audit --audit-level=moderate

# 自動修正（マイナーアップデート）
npm audit fix

# メジャーバージョンも含めて修正
npm audit fix --force  # 注意: 破壊的変更の可能性

# 出力例:
# found 3 vulnerabilities (1 moderate, 2 high)
# run `npm audit fix` to fix 2 of them.
```

**推奨**: 毎週実行、依存関係更新時

---

### 5. シークレットスキャン (TruffleHog)

```bash
# インストール（初回のみ）
pip install trufflehog

# リポジトリ全体をスキャン
trufflehog git file://. --json > secrets-scan.json

# 最新のコミットのみ
trufflehog git file://. --since-commit HEAD~1

# 出力例:
# {
#   "SourceType": "git",
#   "SourceName": "file://.",
#   "DetectorType": "AWS",
#   "Verified": false,
#   "Raw": "AKIA...",
# }
```

**推奨**: PR作成時、定期スキャン（週次）

---

## 🤖 GitHub Actions設定

### ステップ1: ワークフローファイルの配置

既に作成済み: `.github/workflows/security.yml`

### ステップ2: Secrets の設定

GitHub リポジトリ > Settings > Secrets and variables > Actions

**必要なSecrets** (オプション):
```
SLACK_WEBHOOK_URL          # セキュリティアラート通知先
SECURITY_EMAIL            # アラートメール送信先
```

### ステップ3: ワークフローの有効化

```bash
git add .github/workflows/security.yml
git commit -m "ci: Add security scanning workflow"
git push origin main
```

### ステップ4: ステータスバッジの追加 (オプション)

`README.md` に追加:
```markdown
[![Security](https://github.com/Otoriha/Reco_Meshi/actions/workflows/security.yml/badge.svg)](https://github.com/Otoriha/Reco_Meshi/actions/workflows/security.yml)
```

---

## 📊 CI実行タイミング

### 自動実行トリガー

1. **Pushトリガー** (main, develop ブランチ)
   - すべてのセキュリティスキャン実行
   
2. **Pull Requestトリガー**
   - 差分に対するセキュリティスキャン
   - 新規脆弱性の検出
   
3. **Scheduleトリガー** (毎日午前2時 UTC)
   - 依存関係の脆弱性データベース更新
   - 全体スキャン

### 手動実行

GitHub Actions > Security Checks > Run workflow

---

## 🚨 CI失敗時の対応フロー

### 1. Brakeman で警告が出た場合

```bash
# ローカルで詳細確認
cd backend
bundle exec brakeman --format json --output brakeman-report.json

# レポート確認
cat brakeman-report.json | jq '.warnings[] | {type: .warning_type, message: .message, file: .file, line: .line}'

# 修正後、再スキャン
bundle exec brakeman
```

**対応**:
1. 警告の内容を理解
2. 必要に応じてコード修正
3. 誤検出の場合は `.brakeman.yml` で抑制

`.brakeman.yml` 例:
```yaml
:ignore_warnings:
- :warning_type: SQL
  :warning_code: 0
  :fingerprint: abc123...
  :note: "False positive: params are sanitized"
```

---

### 2. bundler-audit で脆弱性が見つかった場合

```bash
cd backend
bundle audit check

# 出力例:
# Name: nokogiri
# Version: 1.13.0
# Advisory: CVE-2023-XXXXX
# Solution: upgrade to >= 1.13.10
```

**対応**:
```bash
# 特定のgemを更新
bundle update nokogiri

# または全体を更新
bundle update

# テスト実行
bundle exec rspec

# 問題なければコミット
git add Gemfile.lock
git commit -m "security: Update nokogiri to fix CVE-2023-XXXXX"
```

**注意**: メジャーバージョンアップは破壊的変更の可能性があるため、慎重にテスト。

---

### 3. npm audit で脆弱性が見つかった場合

```bash
cd frontend
npm audit

# 自動修正を試行
npm audit fix

# 修正できない場合（メジャーアップデートが必要）
npm audit fix --force  # 注意が必要

# または手動更新
npm install package-name@latest

# テスト実行
npm test
npm run build

# 問題なければコミット
git add package.json package-lock.json
git commit -m "security: Update dependencies to fix vulnerabilities"
```

---

### 4. シークレットが検出された場合

**即座に実行**:
1. 該当のAPIキー/シークレットを**無効化**
2. 新しいシークレットを生成
3. 環境変数を更新
4. Git履歴から削除（BFG Repo-Cleaner使用）

```bash
# BFG Repo-Cleaner を使用してシークレットを履歴から削除
# https://rtyley.github.io/bfg-repo-cleaner/

# バックアップ作成
git clone --mirror https://github.com/Otoriha/Reco_Meshi.git

# シークレット削除
bfg --replace-text passwords.txt Reco_Meshi.git

# 履歴を書き換え
cd Reco_Meshi.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# プッシュ（注意: force push）
git push
```

**重要**: force push前にチーム全体に通知。

---

## 📈 セキュリティメトリクス追跡

### 週次レポート

```bash
# スクリプト例: scripts/security-report.sh
#!/bin/bash

echo "=== Weekly Security Report ==="
echo "Date: $(date)"
echo ""

# Brakeman
echo "## Brakeman Warnings"
cd backend
bundle exec brakeman --quiet --format json | jq '.warnings | length'

# Bundler Audit
echo "## Vulnerable Dependencies"
bundle audit check 2>&1 | grep "Vulnerabilities found" || echo "None"

# npm audit (Frontend)
echo "## Frontend Vulnerabilities"
cd ../frontend
npm audit --json | jq '.metadata.vulnerabilities'

# npm audit (LIFF)
echo "## LIFF Vulnerabilities"
cd ../liff
npm audit --json | jq '.metadata.vulnerabilities'
```

実行:
```bash
chmod +x scripts/security-report.sh
./scripts/security-report.sh > security-report-$(date +%Y%m%d).txt
```

---

## 🎯 目標KPI

### セキュリティKPI

| 指標 | 目標 | 現状 | 期限 |
|------|------|------|------|
| Brakeman High以上の警告 | 0件 | ? | 1週間 |
| 依存関係の脆弱性 (Critical) | 0件 | ? | 即時 |
| 依存関係の脆弱性 (High) | 0件 | ? | 1週間 |
| 依存関係の脆弱性 (Medium) | < 5件 | ? | 1ヶ月 |
| シークレット漏洩 | 0件 | 0件 | 常時 |
| セキュリティパッチ適用率 | 100% | ? | 7日以内 |

---

## 🔄 定期メンテナンスタスク

### 毎週月曜日 (30分)
```bash
# 1. 依存関係の更新チェック
cd backend && bundle outdated
cd ../frontend && npm outdated
cd ../liff && npm outdated

# 2. セキュリティスキャン
cd backend && bundle audit check
cd ../frontend && npm audit
cd ../liff && npm audit

# 3. レポート生成
./scripts/security-report.sh
```

### 毎月1日 (2時間)
```bash
# 1. 依存関係の更新
cd backend && bundle update
cd ../frontend && npm update
cd ../liff && npm update

# 2. テスト実行
cd backend && bundle exec rspec
cd ../frontend && npm test
cd ../liff && npm test

# 3. セキュリティスキャン
# 4. 脆弱性レポート作成
# 5. チームレビュー
```

### 四半期ごと (1日)
- 脅威モデルの見直し
- ペネトレーションテスト
- セキュリティ研修
- インシデントレスポンス訓練

---

## 🛡️ Pre-commit Hook設定（オプション）

コミット前に自動でセキュリティチェックを実行:

### インストール

```bash
# Lefthook (推奨)
gem install lefthook
lefthook install
```

### 設定ファイル: `lefthook.yml`

```yaml
pre-commit:
  parallel: true
  commands:
    brakeman:
      glob: "backend/**/*.rb"
      run: cd backend && bundle exec brakeman --quiet --no-pager --no-exit-on-warn
    
    rubocop-security:
      glob: "backend/**/*.rb"
      run: cd backend && bundle exec rubocop --only Security {staged_files}
    
    secret-scan:
      run: |
        if command -v trufflehog > /dev/null; then
          trufflehog git file://. --since-commit HEAD
        fi

pre-push:
  commands:
    bundler-audit:
      run: cd backend && bundle audit check
    
    npm-audit:
      run: |
        cd frontend && npm audit --audit-level=high
        cd ../liff && npm audit --audit-level=high
```

---

## 📞 サポート・問い合わせ

### CI/CD関連
- GitHub Actions が失敗: DevOpsチーム
- セキュリティスキャンの誤検出: セキュリティチーム

### セキュリティ脆弱性
- **緊急**: security@recomeshi.com
- **一般**: dev@recomeshi.com

---

## 🎓 参考資料

### 公式ドキュメント
- [Brakeman](https://brakemanscanner.org/)
- [bundler-audit](https://github.com/rubysec/bundler-audit)
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [TruffleHog](https://github.com/trufflesecurity/trufflehog)

### ベストプラクティス
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

---

## ✅ 実装チェックリスト

### セットアップ
- [ ] 必要なGem/npmパッケージをインストール
- [ ] `.github/workflows/security.yml` を配置
- [ ] GitHub Secrets を設定
- [ ] ワークフローを有効化
- [ ] ステータスバッジを追加 (オプション)

### ローカル開発
- [ ] Pre-commit hookを設定 (オプション)
- [ ] セキュリティスキャンコマンドを試行
- [ ] チームメンバーに使用方法を共有

### 運用
- [ ] 週次セキュリティレポートのスケジュール設定
- [ ] 月次依存関係更新のカレンダー登録
- [ ] セキュリティKPIダッシュボード作成 (オプション)
- [ ] インシデント対応フローの確認

### ドキュメント
- [ ] READMEにセキュリティセクション追加
- [ ] CONTRIBUTING.mdにセキュリティガイドライン追加
- [ ] セキュリティポリシー (`SECURITY.md`) 作成

---

**最終更新**: 2025年10月8日  
**バージョン**: 1.0

---

## 🚀 次のステップ

1. このチェックリストを完了させる
2. `SECURITY_FIXES_CRITICAL.md` の修正を適用
3. CI/CDパイプラインが正常に動作することを確認
4. チーム全体でセキュリティプラクティスを共有

**目標**: 継続的なセキュリティ監視体制の確立 🛡️
