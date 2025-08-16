class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  
  # Dynamically configure devise modules based on environment variable
  devise_modules = [
    :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable
  ]
  devise_modules << :confirmable if ENV['CONFIRMABLE_ENABLED'] == 'true'
  
  devise(*devise_modules, jwt_revocation_strategy: JwtDenylist)

  # Validations (emailはvalidatableモジュールに委譲)
  validates :name, presence: true, length: { maximum: 50 }

  # JWT payloadの追加クレームを定義（subはdevise-jwtが自動付与）
  def jwt_payload
    is_confirmed = if ENV['CONFIRMABLE_ENABLED'] == 'true'
                     confirmed_at.present?
                   else
                     true
                   end

    { 'email' => email, 'confirmed' => is_confirmed }
  end
end
