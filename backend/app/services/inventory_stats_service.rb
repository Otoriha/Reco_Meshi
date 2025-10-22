# ユーザーの在庫情報を効率的に集計するサービス
class InventoryStatsService
  def initialize(user)
    @user = user
  end

  # 利用可能な在庫数（available ステータスのみ）
  def total_count
    @user.user_ingredients.available.count
  end

  # 期限切れ間近の食材（3日以内、既存スコープを再利用）
  def expiring_soon_ingredients
    @user.user_ingredients.expiring_soon(3).includes(:ingredient).limit(3)
  end

  # 在庫が存在するか
  def has_ingredients?
    total_count > 0
  end
end
