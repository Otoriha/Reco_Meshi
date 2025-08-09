class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Validations (emailはvalidatableモジュールに委譲)
  validates :name, presence: true, length: { maximum: 50 }
end
