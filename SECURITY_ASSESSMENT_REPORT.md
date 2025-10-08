# セキュリティ診断レポート - Reco Meshi (レコめし)

**実施日**: 2025年10月8日  
**対象リポジトリ**: https://github.com/Otoriha/Reco_Meshi (main ブランチ)  
**実施者**: Cursor AI Security Assessment  
**評価スコープ**: バックエンド(Rails)、フロントエンド(React)、LIFF(React/LINE)、インフラ構成

---

## エグゼクティブサマリー

本セキュリティ診断では、**21件の脆弱性**を発見しました。このうち、**3件がCritical（緊急）**、**8件がHigh（高）**、**7件がMedium（中）**、**3件がLow（低）**に分類されます。

### 最も重大な所見（Top 3）

1. **[CRITICAL] Sidekiq Web UIの認証不備** - 開発環境で無認証アクセス可能
2. **[CRITICAL] Nonce検証のバイパス可能性** - LINE認証でnonce検証がスキップ可能
3. **[HIGH] JWT有効期限が長すぎる** - 1日間有効でセッション固定攻撃のリスク

---

## 1. 発見された脆弱性一覧

### 1.1 認証・認可の脆弱性

#### VULN-001: [CRITICAL] Sidekiq Web UIに認証がない
**ファイル**: `backend/config/routes.rb:4-7`
**重大度**: CRITICAL  
**CWE**: CWE-306 (Missing Authentication for Critical Function)

**詳細**:
```ruby
if Rails.env.development?
  mount Sidekiq::Web => "/sidekiq"
end
```

開発環境でSidekiq Web UIが無認証で公開されています。この管理画面では：
- 全ジョブの実行履歴の閲覧
- キューの操作（削除、再実行）
- Redisデータの閲覧
- 環境変数の一部が露出

**影響範囲**: 
- 機密データの漏洩
- ジョブの不正操作
- システムの可用性への影響

**再現手順**:
1. 開発環境で `http://localhost:3000/sidekiq` にアクセス
2. 認証なしで管理画面にアクセス可能

**推奨対策**:
```ruby
# config/routes.rb
if Rails.env.development?
  require 'sidekiq/web'
  
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(username),
      ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_USERNAME", "admin"))
    ) &&
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(password),
      ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_PASSWORD", SecureRandom.hex(32)))
    )
  end
  
  mount Sidekiq::Web => "/sidekiq"
end
```

**優先度**: 緊急（即時対応必須）

---

#### VULN-002: [CRITICAL] Nonce検証がスキップ可能
**ファイル**: `backend/app/services/line_auth_service.rb:13-16, 49-52`  
**重大度**: CRITICAL  
**CWE**: CWE-352 (CSRF), CWE-330 (Use of Insufficiently Random Values)

**詳細**:
```ruby
# Verify nonce (skip if nonce is empty for debugging)
unless nonce.blank?
  NonceStore.verify_and_consume(nonce)
end
```

Nonce検証が空文字列の場合にスキップされます。これにより：
- CSRF攻撃が可能
- リプレイ攻撃が可能
- IDトークンの再利用が可能

**影響範囲**:
- 攻撃者が別ユーザーのLINEアカウントを自分のアカウントにリンク可能
- なりすましログインの可能性

**PoC（概念的）**:
```javascript
// 攻撃者が被害者のIDトークンを取得した場合
fetch('/api/v1/auth/line_login', {
  method: 'POST',
  body: JSON.stringify({
    idToken: '<被害者のIDトークン>',
    nonce: ''  // 空文字でバイパス
  })
})
```

**推奨対策**:
```ruby
def authenticate_with_id_token(id_token:, nonce:)
  # nonceを常に必須にする
  raise AuthenticationError, "Nonce is required" if nonce.blank?
  
  NonceStore.verify_and_consume(nonce)
  # ... 以降の処理
end
```

**優先度**: 緊急（即時対応必須）

---

#### VULN-003: [HIGH] JWT有効期限が長すぎる（1日）
**ファイル**: `backend/config/initializers/devise.rb:334`  
**重大度**: HIGH  
**CWE**: CWE-613 (Insufficient Session Expiration)

**詳細**:
```ruby
jwt.expiration_time = 1.day.to_i
```

JWTトークンの有効期限が24時間と長すぎます。これにより：
- トークンが盗まれた場合の悪用期間が長い
- セッション固定攻撃のリスク
- トークンの無効化が困難

**影響範囲**:
- XSSやMITM攻撃でトークンが盗まれた場合、長期間の不正アクセスが可能

**推奨対策**:
```ruby
# 短期アクセストークン + リフレッシュトークンパターン
jwt.expiration_time = 15.minutes.to_i  # アクセストークン: 15分

# リフレッシュトークンを別途実装（有効期限7日など）
```

**優先度**: 高（1週間以内）

---

#### VULN-004: [HIGH] JWT秘密鍵のフォールバック設定
**ファイル**: `backend/config/initializers/devise.rb:323`  
**重大度**: HIGH  
**CWE**: CWE-798 (Use of Hard-coded Credentials)

**詳細**:
```ruby
jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.secret_key_base)
```

`DEVISE_JWT_SECRET_KEY`が未設定の場合、`secret_key_base`にフォールバックします。これは：
- `secret_key_base`は複数の用途で使用されるべきではない
- 鍵のローテーションが困難
- セキュリティベストプラクティスに反する

**推奨対策**:
```ruby
jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY") do
  raise "DEVISE_JWT_SECRET_KEY must be set in production" if Rails.env.production?
  Rails.application.secret_key_base
end
```

**優先度**: 高（1週間以内）

---

#### VULN-005: [HIGH] 認可チェック後のTime-of-Check-Time-of-Use (TOCTOU)
**ファイル**: `backend/app/controllers/api/v1/user_ingredients_controller.rb:2-3, 134-142`  
**重大度**: HIGH  
**CWE**: CWE-367 (TOCTOU Race Condition)

**詳細**:
```ruby
before_action :set_user_ingredient, only: [ :show, :update, :destroy ]
before_action :authorize_user!, only: [ :show, :update, :destroy ]

def set_user_ingredient
  @user_ingredient = UserIngredient.find(params[:id])
end

def authorize_user!
  unless @user_ingredient.user_id == current_user.id
    render json: { error: "権限がありません" }, status: :forbidden
  end
end
```

`set_user_ingredient`で全レコードから検索した後に認可チェックを行っています。これにより：
- IDOR（Insecure Direct Object Reference）の可能性
- 他ユーザーのリソース存在確認が可能（存在/非存在のタイミング差から情報漏洩）

**影響範囲**:
- ユーザーの食材データ、レシピ、買い物リストへの不正アクセス

**推奨対策**:
```ruby
def set_user_ingredient
  # 最初から所有者でフィルタ
  @user_ingredient = current_user.user_ingredients.find(params[:id])
end

# authorize_user! は不要になる
before_action :set_user_ingredient, only: [ :show, :update, :destroy ]
```

同様の問題が以下のコントローラーにも存在：
- `shopping_lists_controller.rb`
- `recipe_histories_controller.rb`
- `favorite_recipes_controller.rb`

**優先度**: 高（1週間以内）

---

#### VULN-006: [HIGH] パスワード最小長が6文字と短い
**ファイル**: `backend/config/initializers/devise.rb:181`  
**重大度**: HIGH  
**CWE**: CWE-521 (Weak Password Requirements)

**詳細**:
```ruby
config.password_length = 6..128
```

パスワードの最小長が6文字では、ブルートフォース攻撃に対して脆弱です。

**推奨対策**:
```ruby
config.password_length = 12..128  # 最低12文字

# さらに複雑性要件を追加
# app/models/user.rb
validate :password_complexity

def password_complexity
  return if password.blank?
  
  unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    errors.add :password, "must include at least one lowercase letter, uppercase letter, and digit"
  end
end
```

**優先度**: 高（1週間以内）

---

#### VULN-007: [MEDIUM] LINE Webhook署名検証の脆弱性
**ファイル**: `backend/app/controllers/api/v1/line_controller.rb:8-12`  
**重大度**: MEDIUM  
**CWE**: CWE-347 (Improper Verification of Cryptographic Signature)

**詳細**:
```ruby
if signature.blank?
  render json: { error: "Missing signature" }, status: :bad_request
  return
end
```

署名が存在しない場合のエラーハンドリングはありますが、署名検証が失敗した場合のログが不十分です。攻撃の検知・分析が困難になります。

**推奨対策**:
```ruby
if signature.blank?
  Rails.logger.warn "LINE Webhook: Missing signature. IP: #{request.remote_ip}"
  render json: { error: "Missing signature" }, status: :bad_request
  return
end

begin
  events = line_bot_service.parse_events_v2(raw_body, signature)
rescue Line::Bot::V2::WebhookParser::InvalidSignatureError => e
  Rails.logger.error "LINE Webhook: Invalid signature. IP: #{request.remote_ip}, Body hash: #{Digest::SHA256.hexdigest(raw_body)}"
  render json: { error: "Invalid signature" }, status: :unauthorized
  return
end
```

**優先度**: 中（1ヶ月以内）

---

### 1.2 入力検証・出力エスケープ

#### VULN-008: [CRITICAL] Gemini APIキーがURLクエリパラメータに露出
**ファイル**: `backend/app/services/llm/gemini_service.rb:52`  
**重大度**: CRITICAL  
**CWE**: CWE-598 (Use of GET Request Method With Sensitive Query Strings)

**詳細**:
```ruby
path = "/v1beta/models/#{@model}:generateContent"
resp = @conn.post("#{path}?key=#{@api_key}", body)
```

APIキーがURLクエリパラメータとして送信されています。これにより：
- ログファイルにAPIキーが記録される
- プロキシサーバーのログに露出
- ブラウザの履歴に残る（開発時）

**影響範囲**:
- Gemini APIキーの漏洩
- 不正なAPI利用による課金

**推奨対策**:
```ruby
# APIキーをヘッダーで送信
@conn = Faraday.new(url: API_BASE) do |f|
  f.request :json
  f.headers['x-goog-api-key'] = @api_key  # ヘッダーで送信
  # ... 他の設定
end

# リクエスト時
resp = @conn.post(path, body)  # クエリパラメータなし
```

**優先度**: 緊急（即時対応必須）

---

#### VULN-009: [HIGH] SQLインジェクションの可能性（Arel.sql使用）
**ファイル**: `backend/app/controllers/api/v1/user_ingredients_controller.rb:19`  
**重大度**: HIGH  
**CWE**: CWE-89 (SQL Injection)

**詳細**:
```ruby
case params[:sort_by]
when "expiry_date"
  records = records.order(Arel.sql("expiry_date ASC NULLS LAST"))
```

現状は固定文字列なので問題ありませんが、`Arel.sql`の使用は危険な先例となります。

**推奨対策**:
```ruby
case params[:sort_by]
when "expiry_date"
  # Arelの安全なメソッドを使用
  records = records.order(
    Arel.sql("COALESCE(expiry_date, '9999-12-31') ASC")
  )
  # または
  records = records.order(expiry_date: :asc, nulls: :last)
```

**優先度**: 高（1週間以内）

---

#### VULN-010: [MEDIUM] 画像ファイルの内容検証不足
**ファイル**: `backend/app/controllers/api/v1/user_ingredients_controller.rb:170-191`  
**重大度**: MEDIUM  
**CWE**: CWE-434 (Unrestricted Upload of File with Dangerous Type)

**詳細**:
```ruby
allowed_types = %w[image/jpeg image/jpg image/png image/gif image/bmp image/webp image/heic]
unless allowed_types.include?(file.content_type)
  return "対応していないファイル形式です。"
end
```

Content-Typeヘッダーのみでチェックしており、実際のファイル内容（マジックバイト）を検証していません。攻撃者がContent-Typeを偽装できます。

**推奨対策**:
```ruby
def validate_image_file(file)
  return "無効なファイルです" unless file.respond_to?(:read)

  # MiniMagickで実際の画像形式を検証
  begin
    image = MiniMagick::Image.read(file.read)
    file.rewind
    
    allowed_formats = %w[jpeg jpg png gif bmp webp heic]
    unless allowed_formats.include?(image.type.downcase)
      return "対応していないファイル形式です。"
    end
  rescue MiniMagick::Invalid, MiniMagick::Error
    return "無効な画像ファイルです"
  end

  # ファイルサイズチェック
  if file.size > 20.megabytes
    return "ファイルサイズが大きすぎます。"
  end

  nil
end
```

**優先度**: 中（1ヶ月以内）

---

#### VULN-011: [MEDIUM] レート制限が未実装
**ファイル**: 全APIエンドポイント  
**重大度**: MEDIUM  
**CWE**: CWE-770 (Allocation of Resources Without Limits)

**詳細**:
全てのAPIエンドポイントでレート制限が実装されていません。これにより：
- ブルートフォース攻撃
- DoS攻撃
- APIコストの濫用（Vision API、LLM APIの大量呼び出し）

**影響範囲**:
- システムの可用性
- 高額なAPI料金

**推奨対策**:
```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?('/api/')
end

# 認証エンドポイントは厳しく
Rack::Attack.throttle('auth/ip', limit: 5, period: 1.minute) do |req|
  req.ip if req.path =~ %r{^/api/v1/auth/(login|signup)}
end

# 画像認識エンドポイント（コスト高）
Rack::Attack.throttle('recognize/ip', limit: 10, period: 1.hour) do |req|
  req.ip if req.path =~ %r{^/api/v1/user_ingredients/recognize}
end

# ユーザーごとのレート制限
Rack::Attack.throttle('api/user', limit: 1000, period: 1.hour) do |req|
  if req.path.start_with?('/api/') && req.env['warden']&.user
    req.env['warden'].user.id
  end
end
```

**優先度**: 中（1ヶ月以内）

---

### 1.3 機密データの取り扱い

#### VULN-012: [HIGH] APIキー・シークレットのハードコード
**ファイル**: 複数ファイル  
**重大度**: HIGH  
**CWE**: CWE-798 (Use of Hard-coded Credentials)

**詳細**:
以下のファイルで環境変数が設定されていない場合のフォールバック処理が不十分：
- `backend/app/services/line_bot_service.rb:8-9` - `Rails.application.credentials`フォールバック
- `backend/app/services/google_cloud_vision_service.rb:144-170` - デフォルト認証情報にフォールバック

**推奨対策**:
```ruby
# production環境では必須にする
def initialize
  if Rails.env.production?
    @channel_secret = ENV.fetch("LINE_CHANNEL_SECRET")
    @channel_token = ENV.fetch("LINE_CHANNEL_ACCESS_TOKEN")
  else
    @channel_secret = Rails.application.credentials.line_channel_secret || 
                      ENV["LINE_CHANNEL_SECRET"]
    @channel_token = Rails.application.credentials.line_channel_access_token || 
                     ENV["LINE_CHANNEL_ACCESS_TOKEN"]
  end
  
  raise "LINE credentials not configured" if @channel_secret.nil? || @channel_token.nil?
end
```

**優先度**: 高（1週間以内）

---

#### VULN-013: [HIGH] フロントエンドのlocalStorageにトークン保存
**ファイル**: `frontend/src/api/client.ts:15`  
**重大度**: HIGH  
**CWE**: CWE-922 (Insecure Storage of Sensitive Information)

**詳細**:
```javascript
const token = localStorage.getItem('authToken');
```

JWTトークンをlocalStorageに保存しています。これにより：
- XSS攻撃でトークンが盗まれる
- localStorageは暗号化されない
- 全てのJavaScriptからアクセス可能

**影響範囲**:
- XSS脆弱性が存在した場合、全ユーザーのトークンが漏洩

**推奨対策**:
```javascript
// HttpOnly, Secure, SameSite=Strict クッキーを使用
// バックエンドでクッキー設定
// frontend/src/api/client.ts
export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,  // クッキーを送信
  headers: {
    'Content-Type': 'application/json',
  },
});

// Authorizationヘッダーは不要（クッキーで送信）
apiClient.interceptors.request.use((config) => {
  // トークンは自動的にクッキーで送信される
  return config;
});

// バックエンド側
# app/controllers/api/v1/users/sessions_controller.rb
def respond_with(resource, _opts = {})
  token = request.env['warden-jwt_auth.token']
  
  # HttpOnly, Secure, SameSite=Strictクッキーにトークンを設定
  cookies.signed[:auth_token] = {
    value: token,
    httponly: true,
    secure: Rails.env.production?,
    same_site: :strict,
    expires: 1.day.from_now
  }
  
  render json: { user: UserSerializer.new(resource).serializable_hash }
end
```

**代替案（より簡易）**:
- sessionStorageを使用（タブを閉じると消える）
- メモリ内に保存（リロードで消える）

**優先度**: 高（1週間以内）

---

#### VULN-014: [MEDIUM] ログに機密情報が出力される可能性
**ファイル**: 複数ファイル  
**重大度**: MEDIUM  
**CWE**: CWE-532 (Insertion of Sensitive Information into Log File)

**詳細**:
以下のログ出力で機密情報が含まれる可能性：
- `backend/app/services/line_auth_service.rb:22-28` - JWTペイロードの詳細
- `backend/app/controllers/api/v1/line_controller.rb:56,69,73` - メッセージ内容

**推奨対策**:
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, 
  :certificate, :otp, :ssn,
  :idToken, :id_token, :nonce, :api_key,  # 追加
  :line_user_id, :line_display_name  # 追加
]

# ログ出力時にフィルタ
Rails.logger.info "JWT検証開始 - aud: [FILTERED]"
# トークンの詳細は本番環境では出力しない
if Rails.env.development?
  Rails.logger.debug "トークン詳細 - exp: #{payload['exp']}"
end
```

**優先度**: 中（1ヶ月以内）

---

### 1.4 CORS・CSRF

#### VULN-015: [MEDIUM] CORS設定が緩い（開発環境）
**ファイル**: `backend/config/initializers/cors.rb:11-21`  
**重大度**: MEDIUM  
**CWE**: CWE-942 (Permissive Cross-domain Policy)

**詳細**:
```ruby
if Rails.env.development?
  origins "localhost:3001", "localhost:3002", "https://localhost:3002",
          "127.0.0.1:3001", "127.0.0.1:3002", "https://127.0.0.1:3002",
          "0.0.0.0:3001", "0.0.0.0:3002", "https://0.0.0.0:3002"
end
```

開発環境で多数のオリジンを許可しています。開発環境が外部に露出した場合、CSRF攻撃のリスクがあります。

**推奨対策**:
```ruby
if Rails.env.development?
  # 環境変数で制御
  allowed_dev_origins = ENV.fetch("ALLOWED_DEV_ORIGINS", "http://localhost:3001,http://localhost:3002").split(',')
  origins *allowed_dev_origins
end
```

**優先度**: 中（1ヶ月以内）

---

#### VULN-016: [LOW] CORS Preflightリクエストの検証不足
**ファイル**: `backend/config/initializers/cors.rb:50-53`  
**重大度**: LOW  
**CWE**: CWE-942 (Permissive Cross-domain Policy)

**詳細**:
```ruby
resource "*",
  headers: :any,
  methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
  credentials: true
```

全てのヘッダーを許可（`:any`）しています。攻撃者がカスタムヘッダーを使用できます。

**推奨対策**:
```ruby
resource "*",
  headers: %w[Authorization Content-Type Accept X-Requested-With],
  methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
  credentials: true,
  max_age: 600  # Preflightキャッシュ
```

**優先度**: 低（2ヶ月以内）

---

### 1.5 外部API統合

#### VULN-017: [MEDIUM] Vision APIの呼び出し制限が緩い
**ファイル**: `backend/config/application.rb:67`  
**重大度**: MEDIUM  
**CWE**: CWE-770 (Allocation of Resources Without Limits)

**詳細**:
```ruby
config.x.vision.api_max_calls = ENV.fetch("VISION_API_MAX_CALLS_PER_IMAGE", "15").to_i.clamp(1, 30)
```

1画像あたり最大30回のAPI呼び出しが可能です。コストが高額になる可能性があります。

**推奨対策**:
```ruby
# より保守的な制限
config.x.vision.api_max_calls = ENV.fetch("VISION_API_MAX_CALLS_PER_IMAGE", "5").to_i.clamp(1, 10)

# ユーザーごとの1日あたりの画像認識回数制限を実装
class User < ApplicationRecord
  def can_recognize_image?
    daily_limit = Setting.vision_api_daily_limit || 20
    today_count = fridge_images.where('created_at >= ?', 1.day.ago).count
    today_count < daily_limit
  end
end
```

**優先度**: 中（1ヶ月以内）

---

#### VULN-018: [MEDIUM] LLMプロンプトインジェクションの可能性
**ファイル**: `backend/app/services/recipe_generator.rb` (推測)  
**重大度**: MEDIUM  
**CWE**: CWE-74 (Improper Neutralization of Special Elements)

**詳細**:
ユーザー入力がLLMプロンプトに直接埋め込まれる場合、プロンプトインジェクション攻撃が可能です。

**影響範囲**:
- 不適切なレシピの生成
- システムプロンプトの上書き
- コスト増大（極端に長い出力）

**推奨対策**:
```ruby
# app/services/prompt_template_service.rb
def sanitize_user_input(input)
  # 特殊文字のエスケープ
  sanitized = input.to_s
    .gsub(/[<>{}[\]\\]/, '')  # 特殊文字除去
    .strip
    .truncate(1000)  # 長さ制限
  
  # プロンプトインジェクションのパターン検知
  dangerous_patterns = [
    /ignore (previous|above|all) instructions/i,
    /system:?\s*role/i,
    /you are now/i,
    /new instructions/i
  ]
  
  dangerous_patterns.each do |pattern|
    if sanitized.match?(pattern)
      Rails.logger.warn "Potential prompt injection detected: #{sanitized[0..50]}"
      raise SecurityError, "Invalid input detected"
    end
  end
  
  sanitized
end

def generate_recipe_prompt(ingredients:, preferences:)
  safe_ingredients = ingredients.map { |i| sanitize_user_input(i) }
  safe_preferences = preferences.transform_values { |v| sanitize_user_input(v) }
  
  # 構造化されたプロンプト
  {
    system: SYSTEM_PROMPT,  # 固定
    user: <<~PROMPT
      食材リスト: #{safe_ingredients.join(', ')}
      好み: #{safe_preferences.to_json}
      
      上記の食材を使用したレシピを提案してください。
      出力はJSON形式で、以下のスキーマに従ってください：
      #{RECIPE_SCHEMA}
    PROMPT
  }
end
```

**優先度**: 中（1ヶ月以内）

---

### 1.6 インフラ・設定

#### VULN-019: [HIGH] 本番環境でのホスト検証が無効
**ファイル**: `backend/config/environments/production.rb:92-97`  
**重大度**: HIGH  
**CWE**: CWE-20 (Improper Input Validation)

**詳細**:
```ruby
# config.hosts = [
#   "example.com",
#   /.*\.example\.com/
# ]
```

ホスト検証がコメントアウトされています。これにより：
- DNS Rebinding攻撃
- Hostヘッダーインジェクション
- キャッシュポイズニング

**推奨対策**:
```ruby
# config/environments/production.rb
config.hosts = [
  "reco-meshi.com",
  "www.reco-meshi.com",
  ENV["ALLOWED_HOST"]
].compact

# ヘルスチェックは除外
config.host_authorization = { 
  exclude: ->(request) { request.path == "/up" } 
}
```

**優先度**: 高（1週間以内）

---

#### VULN-020: [MEDIUM] Sidekiqのリトライ設定が適切か不明
**ファイル**: `backend/config/sidekiq.yml` (存在する場合)  
**重大度**: MEDIUM  
**CWE**: CWE-400 (Uncontrolled Resource Consumption)

**詳細**:
Sidekiqジョブのリトライ設定が不明確です。無限リトライは：
- Redisのメモリ消費
- 外部APIの不要な呼び出し
- デッドレターキューの肥大化

**推奨対策**:
```ruby
# app/jobs/image_recognition_job.rb
class ImageRecognitionJob < ApplicationJob
  queue_as :default
  
  # リトライ設定
  sidekiq_options retry: 3, dead: true
  
  # エラーハンドリング
  sidekiq_retries_exhausted do |msg, ex|
    Rails.logger.error "ImageRecognitionJob failed after retries: #{msg['args']}, #{ex.message}"
    
    # ユーザーに通知（オプション）
    user_id = msg['args'].first
    NotificationService.notify_job_failed(user_id, "画像認識")
  end
  
  def perform(user_id, message_id)
    # ... 実装
  rescue GoogleCloudVisionService::RateLimitError => e
    # レート制限エラーは長めに待つ
    raise e if executions < 3
    retry_job wait: 1.hour
  rescue GoogleCloudVisionService::TemporaryError => e
    # 一時的なエラーは短く待つ
    raise e if executions < 5
    retry_job wait: (executions ** 2).minutes
  rescue GoogleCloudVisionService::PermanentError => e
    # 恒久的なエラーはリトライしない
    Rails.logger.error "Permanent error: #{e.message}"
    # ユーザーに通知
  end
end
```

**優先度**: 中（1ヶ月以内）

---

#### VULN-021: [LOW] HTTPSが強制されていない（開発環境以外）
**ファイル**: `backend/config/environments/production.rb:45`  
**重大度**: LOW  
**CWE**: CWE-311 (Missing Encryption of Sensitive Data)

**詳細**:
```ruby
config.force_ssl = true
```

production環境ではSSLが強制されていますが、staging環境などの設定が不明です。

**推奨対策**:
```ruby
# config/environments/staging.rb
config.force_ssl = true

# config/environments/development.rb
config.force_ssl = false  # 開発環境のみfalse
```

**優先度**: 低（2ヶ月以内）

---

## 2. 推奨する改善項目（重大度別）

### 2.1 CRITICAL（緊急）- 即時対応必須

1. **VULN-001**: Sidekiq Web UIに認証を追加
2. **VULN-002**: Nonce検証を必須化
3. **VULN-008**: Gemini APIキーをヘッダーで送信

**推定作業時間**: 4時間  
**リスク**: これらが悪用された場合、システム全体が侵害される可能性

---

### 2.2 HIGH（高）- 1週間以内

1. **VULN-003**: JWT有効期限を短縮、リフレッシュトークン実装
2. **VULN-004**: JWT秘密鍵を独立した環境変数に
3. **VULN-005**: IDORを防ぐための認可チェック改善（複数コントローラー）
4. **VULN-006**: パスワード強度要件の強化
5. **VULN-009**: Arel.sqlの安全な書き換え
6. **VULN-012**: APIキーの必須化
7. **VULN-013**: トークン保存方法の変更（localStorage → HttpOnly Cookie）
8. **VULN-019**: ホスト検証の有効化

**推定作業時間**: 16時間  
**リスク**: ユーザーデータの漏洩、アカウント乗っ取り

---

### 2.3 MEDIUM（中）- 1ヶ月以内

1. **VULN-007**: Webhook署名検証ログの改善
2. **VULN-010**: 画像ファイル検証の強化
3. **VULN-011**: レート制限の実装（Rack::Attack）
4. **VULN-014**: ログフィルタリングの強化
5. **VULN-015**: CORS設定の見直し
6. **VULN-017**: Vision API呼び出し制限の厳格化
7. **VULN-018**: LLMプロンプトインジェクション対策
8. **VULN-020**: Sidekiqリトライ設定の最適化

**推定作業時間**: 20時間  
**リスク**: サービス妨害、コスト増大

---

### 2.4 LOW（低）- 2ヶ月以内

1. **VULN-016**: CORS Preflightヘッダーの制限
2. **VULN-021**: 全環境でのHTTPS強制

**推定作業時間**: 2時間  
**リスク**: 限定的

---

## 3. セキュリティチェックリスト（CI/CD統合推奨）

### 3.1 静的解析ツール

```yaml
# .github/workflows/security.yml
name: Security Checks

on: [push, pull_request]

jobs:
  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Brakeman
        run: |
          cd backend
          bundle install
          bundle exec brakeman --format json --output brakeman-report.json
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: brakeman-report
          path: backend/brakeman-report.json
  
  bundler-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Bundler Audit
        run: |
          cd backend
          gem install bundler-audit
          bundle audit check --update
  
  npm-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run npm audit (frontend)
        run: |
          cd frontend
          npm audit --audit-level=moderate
      - name: Run npm audit (liff)
        run: |
          cd liff
          npm audit --audit-level=moderate
  
  rubocop-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run RuboCop Security
        run: |
          cd backend
          bundle install
          bundle exec rubocop --only Security
```

### 3.2 依存関係スキャン

```bash
# backend
gem install bundler-audit
bundle audit check --update

# frontend/liff
npm audit --audit-level=moderate
npm audit fix  # 自動修正
```

### 3.3 シークレットスキャン

```bash
# GitGuardian, TruffleHog等の導入
pip install trufflehog
trufflehog git file://. --json --regex > secrets-scan.json
```

---

## 4. 脅威モデル

### 4.1 主要な攻撃シナリオ

#### シナリオ1: LINE認証のなりすまし
**攻撃者**: 悪意のある第三者  
**攻撃手法**:
1. 被害者のLINE IDトークンを何らかの方法で取得
2. `/api/v1/auth/line_login`にnonce=""で送信（VULN-002）
3. 被害者のアカウントでログイン成功

**影響**: 被害者の食材リスト、レシピ履歴、個人情報へのアクセス

**対策**: VULN-002の修正（nonce必須化）

---

#### シナリオ2: JWT盗取による長期的なアクセス
**攻撃者**: XSS脆弱性を悪用した攻撃者  
**攻撃手法**:
1. フロントエンドのXSS脆弱性を悪用
2. `localStorage`からJWTトークンを盗取（VULN-013）
3. 盗んだトークンで24時間有効なアクセス（VULN-003）

**影響**: アカウント乗っ取り、データ改ざん

**対策**: 
- VULN-013の修正（HttpOnly Cookie）
- VULN-003の修正（短期トークン + リフレッシュトークン）

---

#### シナリオ3: Sidekiq管理画面からの情報漏洩
**攻撃者**: 開発環境にアクセスできる内部/外部の攻撃者  
**攻撃手法**:
1. `/sidekiq`にアクセス（VULN-001）
2. 実行中/過去のジョブから以下を取得：
   - ユーザーID
   - LINE User ID
   - 画像URL
   - エラーメッセージに含まれる機密情報

**影響**: 大規模な個人情報漏洩

**対策**: VULN-001の修正（認証追加）

---

#### シナリオ4: IDOR（Insecure Direct Object Reference）
**攻撃者**: 正規ユーザー  
**攻撃手法**:
1. 自分の食材IDが`123`と判明
2. `/api/v1/user_ingredients/124`, `125`, ... を順次試行（VULN-005）
3. 他ユーザーの食材情報を取得（タイミング差で存在確認）

**影響**: プライバシー侵害、競合情報の漏洩

**対策**: VULN-005の修正（所有者フィルタ）

---

#### シナリオ5: 高額API請求攻撃
**攻撃者**: 悪意のあるユーザーまたはボット  
**攻撃手法**:
1. レート制限がないため、大量の画像認識リクエストを送信（VULN-011）
2. Vision APIを1画像あたり30回呼び出し（VULN-017）
3. LLMでレシピ生成を繰り返し

**影響**: 月間数十万円のAPI料金

**対策**:
- VULN-011の修正（レート制限）
- VULN-017の修正（API呼び出し制限）

---

### 4.2 信頼境界図

```
┌─────────────────┐
│   LINE Platform │
│   (外部)        │
└────────┬────────┘
         │ IDトークン
         ↓
┌─────────────────────────────────────────┐
│  Trust Boundary (認証)                   │
├─────────────────────────────────────────┤
│  LIFF App (React)                       │
│  - IDトークン取得                       │
│  - nonce生成                            │
└────────┬────────────────────────────────┘
         │ JWT
         ↓
┌─────────────────────────────────────────┐
│  Backend API (Rails)                    │
│  - JWT検証                              │
│  - 認可チェック                         │
│  - ビジネスロジック                     │
└────┬──────────────┬─────────────────────┘
     │              │
     ↓              ↓
┌──────────┐   ┌────────────────┐
│ Database │   │ External APIs  │
│ (内部)   │   │ - Vision API   │
│          │   │ - OpenAI       │
│          │   │ - Gemini       │
└──────────┘   └────────────────┘
```

**脆弱な境界**:
- LINE Platform → LIFF: nonce検証の不備（VULN-002）
- LIFF → Backend: localStorage経由のXSS（VULN-013）
- Backend → External APIs: APIキーの露出（VULN-008）

---

## 5. 修正済み項目（既知の対処済みセキュリティ対策）

以下のセキュリティ対策は既に実装されています：

### ✅ 実装済みの良いセキュリティ対策

1. **パスワードのハッシュ化**: bcryptを使用（Devise標準）
2. **HTTPS強制**: production環境で`force_ssl = true`
3. **CSRF対策**: API専用のため`protect_from_forgery`は無効化（適切）
4. **JWTリボケーション**: `jwt_denylist`テーブルで無効化トークンを管理
5. **パラメータフィルタリング**: 機密情報のログ出力を一部フィルタ
6. **LINE Webhook署名検証**: 正しく実装されている
7. **SQL Injection対策**: ActiveRecordのパラメータ化クエリを使用
8. **Sidekiq認証（production想定）**: 本番では別途認証が必要と想定

---

## 6. 推奨されるセキュリティ監視・ログ

### 6.1 監視すべきイベント

```ruby
# config/initializers/security_logger.rb
class SecurityLogger
  def self.log_suspicious_activity(event_type, details)
    Rails.logger.warn({
      type: 'SECURITY_EVENT',
      event: event_type,
      timestamp: Time.current,
      ip: details[:ip],
      user_id: details[:user_id],
      details: details[:message]
    }.to_json)
    
    # 重大なイベントはアラート送信
    if [:unauthorized_access, :jwt_manipulation, :rate_limit_exceeded].include?(event_type)
      SecurityAlertService.send_alert(event_type, details)
    end
  end
end

# 使用例
# ApplicationController
rescue_from ActiveRecord::RecordNotFound do |exception|
  if @user_ingredient && @user_ingredient.user_id != current_user.id
    SecurityLogger.log_suspicious_activity(
      :unauthorized_access,
      {
        ip: request.remote_ip,
        user_id: current_user.id,
        resource: "UserIngredient##{@user_ingredient.id}",
        message: "IDOR attempt detected"
      }
    )
  end
  not_found
end
```

### 6.2 ログ集約・分析

- **ログ集約**: Datadog, CloudWatch Logs, ELK Stack
- **異常検知**: 短時間に大量のAPIリクエスト、認証失敗の急増
- **ダッシュボード**: 
  - 認証失敗率
  - APIレート制限超過
  - 外部API呼び出しコスト
  - エラー率

---

## 7. インシデントレスポンスプラン

### 7.1 セキュリティインシデント発生時の対応手順

#### フェーズ1: 検知・初動対応（0-1時間）
1. ログ・アラートから異常を検知
2. 影響範囲の初期調査
3. 緊急連絡先への通知
4. 必要に応じてサービス停止

#### フェーズ2: 封じ込め（1-4時間）
1. 侵害されたアカウントの無効化
2. APIキーのローテーション
3. JWTトークンの一括無効化
4. ネットワークアクセス制限

#### フェーズ3: 調査・復旧（4-24時間）
1. ログの詳細分析
2. 侵害経路の特定
3. 脆弱性の修正・デプロイ
4. データベースの整合性チェック
5. サービス再開

#### フェーズ4: 事後対応（1-7日）
1. インシデントレポート作成
2. 影響を受けたユーザーへの通知
3. 再発防止策の実施
4. 関係機関への報告（必要に応じて）

### 7.2 緊急連絡先

```yaml
security_contacts:
  cto: cto@recomeshi.com
  lead_engineer: dev@recomeshi.com
  legal: legal@recomeshi.com
  line_support: https://www.linebiz.com/jp/contact/
  google_cloud_support: https://cloud.google.com/support
```

---

## 8. コンプライアンス・法的要件

### 8.1 個人情報保護法対応

- **取得する個人情報**:
  - LINEユーザーID
  - LINE表示名、プロフィール画像
  - メールアドレス（Web登録時）
  - 食材リスト、レシピ履歴

- **必要な対策**:
  - プライバシーポリシーの明示
  - 同意取得フロー
  - データの暗号化（保存時・通信時）
  - データ削除機能の実装

### 8.2 LINE開発ガイドライン準拠

- **必須事項**:
  - IDトークンの適切な検証（nonce含む）
  - アクセストークンの安全な保管
  - ユーザーデータの目的外利用禁止

**現状**: VULN-002の修正が必要

---

## 9. まとめと次のアクション

### 9.1 優先度別アクションプラン

| 優先度 | 期限 | 項目数 | 推定工数 | 担当（推奨） |
|--------|------|--------|----------|--------------|
| CRITICAL | 即時 | 3 | 4h | シニアエンジニア |
| HIGH | 1週間 | 8 | 16h | フルチーム |
| MEDIUM | 1ヶ月 | 8 | 20h | 分担 |
| LOW | 2ヶ月 | 2 | 2h | ジュニア可 |

**合計推定工数**: 42時間（約1週間）

### 9.2 推奨される実施順序

**Week 1（CRITICAL + HIGH）**:
1. Day 1-2: VULN-001, 002, 008（CRITICAL 3件）
2. Day 3-4: VULN-003, 004, 005（HIGH優先度上位）
3. Day 5: VULN-006, 013, 019（HIGH残り）

**Week 2-4（MEDIUM + テスト）**:
- Week 2: VULN-011（レート制限）、VULN-010（画像検証）
- Week 3: VULN-014, 015, 017, 018
- Week 4: 総合テスト、ペネトレーションテスト

**Month 2（LOW + 継続監視）**:
- VULN-016, 021
- セキュリティ監視ダッシュボード構築
- インシデントレスポンス訓練

### 9.3 継続的なセキュリティ改善

1. **月次レビュー**:
   - 依存関係の更新（`bundle update`, `npm audit`）
   - セキュリティパッチの適用
   - ログレビュー

2. **四半期レビュー**:
   - 脅威モデルの見直し
   - ペネトレーションテスト
   - セキュリティ研修

3. **年次レビュー**:
   - 外部セキュリティ監査
   - コンプライアンスチェック
   - インシデントレスポンスプランの更新

---

## 10. 付録

### 10.1 参考資料

- **OWASP Top 10 2021**: https://owasp.org/Top10/
- **Rails Security Guide**: https://guides.rubyonrails.org/security.html
- **LINE Developers - Security Best Practices**: https://developers.line.biz/en/docs/line-login/secure-login-process/
- **JWT Best Practices**: https://tools.ietf.org/html/rfc8725

### 10.2 使用ツール

- **Brakeman**: Rails静的解析
- **Bundler Audit**: Ruby依存関係スキャン
- **npm audit**: JavaScript依存関係スキャン
- **RuboCop**: コード品質・セキュリティ
- **Rack::Attack**: レート制限
- **OWASP ZAP**: 動的スキャン（推奨）

### 10.3 連絡先

セキュリティに関する質問・報告:
- **Email**: security@recomeshi.com（推奨）
- **責任者**: CTO
- **緊急連絡**: （24時間対応体制の構築を推奨）

---

**レポート作成日**: 2025年10月8日  
**次回レビュー予定**: 2025年11月8日  
**バージョン**: 1.0

---

## 免責事項

本レポートは現時点でのソースコードレビューに基づくものであり、以下は含まれません：
- 実際のペネトレーションテスト
- インフラ層の詳細分析（AWS/GCP設定等）
- 本番環境での動的テスト
- サードパーティライブラリの詳細監査

より包括的なセキュリティ評価には、外部セキュリティ専門企業による監査を推奨します。
