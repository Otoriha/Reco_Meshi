class LineUserResolver
  def self.resolve_user_from_line_id(line_user_id)
    return nil if line_user_id.blank?
    
    line_account = LineAccount.find_by(line_user_id: line_user_id)
    line_account&.user
  end
end