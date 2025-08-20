class LineAccount < ApplicationRecord
  belongs_to :user, optional: true

  validates :line_user_id, presence: true, uniqueness: true
  validates :line_display_name, presence: true

  scope :linked, -> { where.not(user_id: nil) }
  scope :unlinked, -> { where(user_id: nil) }

  def linked?
    user_id.present? && linked_at.present?
  end

  def link_to_user!(user)
    update!(user: user, linked_at: Time.current)
  end

  def unlink!
    update!(user: nil, linked_at: nil)
  end
end