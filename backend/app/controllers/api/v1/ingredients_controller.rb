class Api::V1::IngredientsController < ApplicationController
  # 食材マスタは読み取り専用（MVPでは管理者機能なし）

  # GET /api/v1/ingredients
  # Params: category, search, page, per_page
  def index
    ingredients = Ingredient.all
    ingredients = ingredients.by_category(params[:category]) if params[:category].present?
    ingredients = ingredients.search(params[:search]) if params[:search].present?

    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    per_page = [per_page, 100].min
    total = ingredients.count
    items = ingredients.offset((page - 1) * per_page).limit(per_page)

    data = IngredientSerializer.new(items).serializable_hash[:data].map { |d| d[:attributes] }

    render json: {
      status: { code: 200, message: '食材を取得しました。' },
      data: data,
      meta: { total: total, page: page, per_page: per_page }
    }, status: :ok
  end

  # 注意: 食材マスタの追加・編集・削除はMVPでは提供しません
  # 新しい食材は以下の方法で追加されます：
  # 1. 開発者がseeds.rbに追加してデプロイ
  # 2. 画像認識で新食材が検出された際の自動追加（将来実装）
  # 3. 管理者機能の実装後に管理画面から追加（将来実装）
end

