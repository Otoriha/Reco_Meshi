class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Validations (emailはvalidatableモジュールに委譲)
  validates :name, presence: true, length: { maximum: 50 }

  # JWT payloadの追加クレームを定義（subはdevise-jwtが自動付与）
  def jwt_payload
    { 'email' => email }
  end
end
