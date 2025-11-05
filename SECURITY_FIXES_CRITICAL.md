# CRITICAL セキュリティ修正パッチ

このファイルには、直ちに対応が必要な3つのCRITICAL脆弱性の修正方法を記載しています。

---

## VULN-001: Sidekiq Web UIに認証を追加

### 修正ファイル: `backend/config/routes.rb`

**変更前:**
```ruby
if Rails.env.development?
  mount Sidekiq::Web => "/sidekiq"
end
```

**変更後:**
```ruby
if Rails.env.development?
  require 'sidekiq/web'
  
  # Basic認証でSidekiq Web UIを保護
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # タイミング攻撃対策のためにsecure_compareを使用
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(username),
      ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_USERNAME", "admin"))
    ) &&
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(password),
      ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_PASSWORD") { 
        raise "SIDEKIQ_PASSWORD must be set" 
      })
    )
  end
  
  mount Sidekiq::Web => "/sidekiq"
end
```

### 環境変数の設定

`.env.development` に以下を追加:
```bash
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=<強力なパスワードを生成>
```

強力なパスワード生成:
```bash
ruby -e "require 'securerandom'; puts SecureRandom.hex(32)"
```

### Production環境の推奨設定

`config/routes.rb`:
```ruby
# Production環境では、より強固な認証を推奨
if Rails.env.production?
  require 'sidekiq/web'
  
  # Deviseの管理者認証を使用する例
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end
end
```

---

## VULN-002: Nonce検証を必須化

### 修正ファイル: `backend/app/services/line_auth_service.rb`

**変更前:**
```ruby
def authenticate_with_id_token(id_token:, nonce:)
  # Verify nonce (skip if nonce is empty for debugging)
  unless nonce.blank?
    NonceStore.verify_and_consume(nonce)
  end
  # ...
end

def link_existing_user(user:, id_token:, nonce:)
  # Verify nonce (skip if nonce is empty for debugging)
  unless nonce.blank?
    NonceStore.verify_and_consume(nonce)
  end
  # ...
end
```

**変更後:**
```ruby
def authenticate_with_id_token(id_token:, nonce:)
  # nonceは常に必須（セキュリティ上重要）
  if nonce.blank?
    Rails.logger.warn "LINE認証: nonceが提供されていません"
    raise AuthenticationError, "Nonce is required for security"
  end
  
  # nonceの検証と消費
  NonceStore.verify_and_consume(nonce)
  
  # 以降の処理...
  Rails.logger.info "JWT検証開始 - aud: #{ENV['LINE_CHANNEL_ID']}"
  Rails.logger.info "現在時刻: #{Time.current.to_i}"

  # トークンの詳細を確認（開発環境のみ）
  if Rails.env.development?
    begin
      header, payload = JWT.decode(id_token, nil, false)
      Rails.logger.debug "トークン詳細 - exp: #{payload['exp']}, iat: #{payload['iat']}"
    rescue => e
      Rails.logger.warn "トークン詳細取得エラー: #{e.message}"
    end
  end

  line_user_info = JwtVerifier.verify_id_token(
    id_token: id_token,
    aud: ENV["LINE_CHANNEL_ID"],
    nonce: nonce  # nonceは常に検証
  )
  Rails.logger.info "JWT検証成功"

  # Find or create LineAccount
  line_account = find_or_create_line_account(line_user_info)

  # Find or create User
  user = find_or_create_user_for_line_account(line_account, line_user_info)

  { user: user, line_account: line_account }
rescue JwtVerifier::VerificationError, NonceStore::NonceError => e
  raise AuthenticationError, e.message
end

def link_existing_user(user:, id_token:, nonce:)
  # nonceは常に必須
  if nonce.blank?
    Rails.logger.warn "LINE連携: nonceが提供されていません。user_id: #{user.id}"
    raise AuthenticationError, "Nonce is required for security"
  end
  
  # nonceの検証と消費
  NonceStore.verify_and_consume(nonce)

  # Verify ID token
  line_user_info = JwtVerifier.verify_id_token(
    id_token: id_token,
    aud: ENV["LINE_CHANNEL_ID"],
    nonce: nonce  # nonceは常に検証
  )

  line_user_id = line_user_info[:sub]

  # Check if LINE account is already linked to another user
  existing_line_account = LineAccount.find_by(line_user_id: line_user_id)

  if existing_line_account&.user_id.present? && existing_line_account.user_id != user.id
    raise AuthenticationError, "LINE account is already linked to another user"
  end

  # Create or update LineAccount and link to user
  line_account = if existing_line_account
                   existing_line_account.tap do |account|
                     account.update!(
                       user: user,
                       line_display_name: line_user_info[:name],
                       line_picture_url: line_user_info[:picture],
                       linked_at: Time.current
                     )
                   end
  else
                   LineAccount.create!(
                     line_user_id: line_user_id,
                     user: user,
                     line_display_name: line_user_info[:name],
                     line_picture_url: line_user_info[:picture],
                     linked_at: Time.current
                   )
  end

  { user: user, line_account: line_account }
rescue JwtVerifier::VerificationError, NonceStore::NonceError => e
  raise AuthenticationError, e.message
end
```

### 修正ファイル: `backend/app/controllers/api/v1/auth/line_auth_controller.rb`

**変更前:**
```ruby
def validate_line_auth_params
  unless params[:idToken].present? && params[:nonce].present?
    render json: {
      error: {
        code: "invalid_request",
        message: "idTokenとnonceが必要です"
      }
    }, status: :bad_request and return
  end
end
```

**変更後:**
```ruby
def validate_line_auth_params
  # idTokenとnonceの両方を必須にする
  if params[:idToken].blank?
    render json: {
      error: {
        code: "invalid_request",
        message: "idTokenが必要です"
      }
    }, status: :bad_request and return
  end
  
  if params[:nonce].blank?
    Rails.logger.warn "LINE認証: nonceが未提供。IP: #{request.remote_ip}"
    render json: {
      error: {
        code: "invalid_request",
        message: "nonceが必要です。セキュリティのため、nonceは必須です。"
      }
    }, status: :bad_request and return
  end
end
```

### フロントエンド側の対応確認

LIFFアプリ側で必ずnonceを送信していることを確認:

`liff/src/api/client.ts` の確認:
```typescript
// 必ずnonceを生成して送信
const nonceRes = await axiosPlain.post<{ nonce: string }>('/auth/generate_nonce')
const nonce = nonceRes.data?.nonce
if (!nonce) throw new Error('nonce未取得')

const res = await axiosPlain.post<LineAuthResponse>('/auth/line_login', { 
  idToken, 
  nonce  // 必須
})
```

---

## VULN-008: Gemini APIキーをヘッダーで送信

### 修正ファイル: `backend/app/services/llm/gemini_service.rb`

**変更前:**
```ruby
def generate(messages:, response_format: :text, temperature: nil, max_tokens: nil)
  # ...
  path = "/v1beta/models/#{@model}:generateContent"
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  resp = @conn.post("#{path}?key=#{@api_key}", body)  # ❌ URLにAPIキー
  # ...
end
```

**変更後:**
```ruby
module Llm
  class GeminiService < BaseService
    API_BASE = "https://generativelanguage.googleapis.com".freeze

    def initialize(connection: nil)
      @api_key = ENV["GEMINI_API_KEY"]
      raise "Gemini API key is not configured" if @api_key.nil? || @api_key.empty?

      @model = ENV.fetch("GEMINI_MODEL", "gemini-1.5-flash")
      timeout_s = (config_value(:timeout_ms).to_i / 1000.0)
      max_retries = config_value(:max_retries).to_i

      @conn = connection || Faraday.new(url: API_BASE) do |f|
        f.request :json
        f.request :retry, max: max_retries, interval: 0.5, interval_randomness: 0.5, backoff_factor: 2,
                          retry_statuses: [ 429, 500, 502, 503, 504 ],
                          methods: %i[post get],
                          retry_if: ->(env, _exception) { env.response&.status.to_i >= 500 || env.response&.status == 429 }
        f.response :json, content_type: /\bjson$/
        
        # ✅ APIキーをヘッダーで送信（推奨方法）
        f.headers['x-goog-api-key'] = @api_key
        
        f.options.timeout = timeout_s
        f.adapter Faraday.default_adapter
      end
    end

    def generate(messages:, response_format: :text, temperature: nil, max_tokens: nil)
      temperature ||= config_value(:temperature).to_f
      max_tokens ||= config_value(:max_tokens).to_i
      prompt = build_prompt(messages)

      body = {
        contents: [
          {
            role: "user",
            parts: [ { text: prompt } ]
          }
        ],
        generationConfig: {
          temperature: temperature,
          maxOutputTokens: max_tokens
        }
      }
      if response_format == :json
        body[:generationConfig][:response_mime_type] = "application/json"
      end

      path = "/v1beta/models/#{@model}:generateContent"
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      # ✅ クエリパラメータなしでリクエスト（ヘッダーでAPIキー送信）
      resp = @conn.post(path, body)
      
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0).round

      if resp.status >= 400
        error_message = resp.body.is_a?(Hash) ? resp.body['error']&.dig('message') : resp.body
        Rails.logger.error "Gemini API error: #{resp.status} #{error_message}"
        raise "Gemini API error: #{resp.status} #{error_message}"
      end

      text = extract_text(resp.body)
      usage = resp.body["usageMetadata"]

      ActiveSupport::Notifications.instrument("llm.request", {
        provider: "gemini",
        model: @model,
        duration: duration,
        tokens: usage
      })

      result = Llm::Result.new(text: text, provider: "gemini", model: @model, usage: usage)
      if response_format == :json
        begin
          result.raw_json = JSON.parse(text)
        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse Gemini JSON response: #{e.message}"
          # allow caller to fallback to text
        end
      end
      result
    end

    private

    def build_prompt(msgs)
      [ msgs[:system], msgs[:user] ].compact.join("\n\n")
    end

    def extract_text(body)
      candidates = body["candidates"]
      return "" unless candidates && candidates.first
      parts = candidates.first.dig("content", "parts")
      if parts && parts.first && parts.first["text"]
        parts.first["text"]
      else
        ""
      end
    end

    def config_value(key)
      cfg = Rails.application.config.x.llm
      cfg.is_a?(Hash) ? cfg[key] : cfg.public_send(key)
    end
  end
end
```

### 検証方法

修正後、ログにAPIキーが出力されていないことを確認:

```bash
# 開発環境でGemini APIを呼び出し
rails console
> Llm::GeminiService.new.generate(messages: {system: "test", user: "hello"})

# ログを確認（APIキーが出力されていないこと）
tail -f log/development.log | grep -i "api_key\|key="
# 何も表示されないはず
```

また、FaradayのリクエストログでヘッダーにAPIキーが設定されていることを確認:

```ruby
# 開発環境でのデバッグ
connection.use Faraday::Response::Logger, Rails.logger if Rails.env.development?
```

---

## テスト方法

### 1. VULN-001のテスト

```bash
# 修正前: 認証なしでアクセス可能
curl http://localhost:3000/sidekiq
# → Sidekiq Web UIが表示される（脆弱）

# 修正後: 認証が必要
curl http://localhost:3000/sidekiq
# → 401 Unauthorized

curl -u admin:your_password http://localhost:3000/sidekiq
# → Sidekiq Web UIが表示される（安全）
```

### 2. VULN-002のテスト

```bash
# RSpecテストの追加
# spec/services/line_auth_service_spec.rb

RSpec.describe LineAuthService do
  describe '#authenticate_with_id_token' do
    context 'when nonce is blank' do
      it 'raises AuthenticationError' do
        expect {
          LineAuthService.authenticate_with_id_token(
            id_token: 'valid_token',
            nonce: ''
          )
        }.to raise_error(LineAuthService::AuthenticationError, /Nonce is required/)
      end
    end
    
    context 'when nonce is nil' do
      it 'raises AuthenticationError' do
        expect {
          LineAuthService.authenticate_with_id_token(
            id_token: 'valid_token',
            nonce: nil
          )
        }.to raise_error(LineAuthService::AuthenticationError, /Nonce is required/)
      end
    end
    
    context 'when nonce is present' do
      it 'verifies the nonce' do
        # モックを使用してテスト
        allow(NonceStore).to receive(:verify_and_consume).and_return(true)
        allow(JwtVerifier).to receive(:verify_id_token).and_return({
          sub: 'U1234567890',
          name: 'Test User',
          picture: 'https://example.com/pic.jpg'
        })
        
        # 正常系のテスト
        result = LineAuthService.authenticate_with_id_token(
          id_token: 'valid_token',
          nonce: 'valid_nonce'
        )
        
        expect(result).to have_key(:user)
        expect(result).to have_key(:line_account)
      end
    end
  end
end
```

### 3. VULN-008のテスト

```ruby
# spec/services/llm/gemini_service_spec.rb

RSpec.describe Llm::GeminiService do
  describe '#generate' do
    it 'sends API key in header, not in URL' do
      stub_request(:post, %r{https://generativelanguage.googleapis.com/v1beta/models/.+:generateContent})
        .with(
          headers: { 'x-goog-api-key' => ENV['GEMINI_API_KEY'] }
        )
        .to_return(
          status: 200,
          body: {
            candidates: [
              { content: { parts: [{ text: 'Test response' }] } }
            ],
            usageMetadata: {}
          }.to_json
        )
      
      service = Llm::GeminiService.new
      result = service.generate(
        messages: { system: 'test', user: 'hello' }
      )
      
      expect(result.text).to eq('Test response')
      
      # URLにAPIキーが含まれていないことを確認
      expect(WebMock).to have_requested(:post, %r{generateContent$})
        .with { |req| !req.uri.query&.include?('key=') }
    end
  end
end
```

---

## デプロイ手順

### 1. 環境変数の設定

**開発環境** (`.env.development`):
```bash
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=<生成した強力なパスワード>
```

**本番環境** (環境変数):
```bash
# Heroku
heroku config:set SIDEKIQ_USERNAME=admin
heroku config:set SIDEKIQ_PASSWORD=<強力なパスワード>

# Docker / Fly.io
fly secrets set SIDEKIQ_USERNAME=admin
fly secrets set SIDEKIQ_PASSWORD=<強力なパスワード>
```

### 2. コードの適用

```bash
# 修正をコミット
git add backend/config/routes.rb
git add backend/app/services/line_auth_service.rb
git add backend/app/controllers/api/v1/auth/line_auth_controller.rb
git add backend/app/services/llm/gemini_service.rb

git commit -m "security: Fix CRITICAL vulnerabilities (VULN-001, 002, 008)

- Add authentication to Sidekiq Web UI
- Make nonce validation mandatory for LINE auth
- Move Gemini API key from URL to header"
```

### 3. テストの実行

```bash
cd backend
bundle exec rspec spec/services/line_auth_service_spec.rb
bundle exec rspec spec/services/llm/gemini_service_spec.rb
bundle exec rspec spec/requests/api/v1/auth/line_auth_spec.rb
```

### 4. デプロイ

```bash
# 本番環境にデプロイ
git push production main

# または
fly deploy
```

### 5. デプロイ後の確認

```bash
# Sidekiq認証の確認
curl -I https://your-app.com/sidekiq
# → 401 Unauthorized が返ることを確認

# LINE認証の確認（nonceなし）
curl -X POST https://your-app.com/api/v1/auth/line_login \
  -H "Content-Type: application/json" \
  -d '{"idToken": "test", "nonce": ""}'
# → 400 Bad Request "nonceが必要です" が返ることを確認
```

---

## ロールバック手順

万が一問題が発生した場合:

```bash
# 前のバージョンに戻す
git revert HEAD
git push production main

# または、特定のコミットに戻す
git reset --hard <commit_hash>
git push production main --force  # 注意: forceプッシュは慎重に
```

---

## 完了チェックリスト

- [ ] 環境変数の設定完了（開発・本番）
- [ ] コード修正の適用
- [ ] テストの追加・実行
- [ ] ローカルでの動作確認
- [ ] ステージング環境でのテスト
- [ ] 本番環境へのデプロイ
- [ ] 本番環境での動作確認
- [ ] チーム全体への周知
- [ ] ドキュメントの更新

---

## 次のステップ

これらのCRITICAL脆弱性を修正した後、引き続きHIGH脆弱性の対応を進めてください：

1. JWT有効期限の短縮（VULN-003）
2. JWT秘密鍵の分離（VULN-004）
3. IDOR対策（VULN-005）
4. パスワード強度要件（VULN-006）
5. その他HIGH脆弱性...

詳細は `SECURITY_ASSESSMENT_REPORT.md` を参照してください。
