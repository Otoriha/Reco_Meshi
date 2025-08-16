class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
  # Note: :confirmable will be re-enabled in Issue #58 with proper email configuration

  # Validations (emailはvalidatableモジュールに委譲)
  validates :name, presence: true, length: { maximum: 50 }

  # JWT payloadの追加クレームを定義（subはdevise-jwtが自動付与）
  def jwt_payload
    { 'email' => email, 'confirmed' => true } # Always true until Issue #58 implements email confirmation
  end
end
