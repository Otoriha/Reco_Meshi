class ConfirmExistingUsers < ActiveRecord::Migration[7.2]
  def up
    # Confirm all existing users who haven't been confirmed yet
    # This is necessary because we're enabling the confirmable module
    User.where(confirmed_at: nil).update_all(
      confirmed_at: Time.current,
      confirmation_sent_at: Time.current
    )
  end

  def down
    # On rollback, do nothing to preserve user data
  end
end
