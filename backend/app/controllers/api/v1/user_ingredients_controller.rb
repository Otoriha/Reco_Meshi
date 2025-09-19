class Api::V1::UserIngredientsController < ApplicationController
  before_action :set_user_ingredient, only: [ :show, :update, :destroy ]
  before_action :authorize_user!, only: [ :show, :update, :destroy ]

  # GET /api/v1/user_ingredients
  # Params: status, category, sort_by, group_by
  def index
    records = current_user.user_ingredients.includes(:ingredient)

    # Status filtering
    records = records.where(status: params[:status]) if params[:status].present?

    # Category filtering
    records = records.by_category(params[:category]) if params[:category].present?

    # Sorting
    case params[:sort_by]
    when "expiry_date"
      records = records.order(Arel.sql("expiry_date ASC NULLS LAST"))
    when "quantity"
      records = records.order(quantity: :desc)
    else
      records = records.recent
    end

    if params[:group_by].to_s == "category"
      grouped = records.group_by { |ui| ui.ingredient.category }
      data = {}
      grouped.each do |category, items|
        data[category] = items.map do |item|
          UserIngredientSerializer.new(item).serializable_hash[:data][:attributes]
        end
      end
      render json: { status: { code: 200, message: "在庫を取得しました。" }, data: data }, status: :ok
    else
      data = records.map do |record|
        UserIngredientSerializer.new(record).serializable_hash[:data][:attributes]
      end
      render json: { status: { code: 200, message: "在庫を取得しました。" }, data: data }, status: :ok
    end
  end

  # GET /api/v1/user_ingredients/:id
  def show
    render json: {
      status: { code: 200, message: "在庫を取得しました。" },
      data: UserIngredientSerializer.new(@user_ingredient).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  # POST /api/v1/user_ingredients
  def create
    attrs = user_ingredient_params.merge(user_id: current_user.id)
    record = UserIngredient.create!(attrs)

    render json: {
      status: { code: 201, message: "在庫を追加しました。" },
      data: UserIngredientSerializer.new(record).serializable_hash[:data][:attributes]
    }, status: :created
  end

  # PUT /api/v1/user_ingredients/:id
  def update
    @user_ingredient.update!(user_ingredient_update_params)
    render json: {
      status: { code: 200, message: "在庫を更新しました。" },
      data: UserIngredientSerializer.new(@user_ingredient).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  # DELETE /api/v1/user_ingredients/:id
  def destroy
    @user_ingredient.destroy
    head :no_content
  end

  # POST /api/v1/user_ingredients/recognize
  def recognize
    # 画像ファイルのバリデーション
    image_files = extract_image_files
    if image_files.empty?
      return render json: {
        success: false,
        message: "画像ファイルが提供されていません",
        recognized_ingredients: [],
        conversion_metrics: {}
      }, status: :bad_request
    end

    # 複数画像の場合は最初の画像のみ処理（将来拡張可能）
    image_file = image_files.first

    # ファイル形式とサイズのバリデーション
    validation_error = validate_image_file(image_file)
    if validation_error
      return render json: {
        success: false,
        message: validation_error,
        recognized_ingredients: [],
        conversion_metrics: {}
      }, status: :bad_request
    end

    begin
      # 画像認識サービスを呼び出し
      recognition_service = ImageRecognitionService.new(
        user: current_user,
        image_source: image_file
      )

      result = recognition_service.recognize_and_convert

      if result[:success]
        render json: result, status: :ok
      else
        render json: result, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Image recognition API error: #{e.class}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace&.first(3)&.join(', ')}"

      render json: {
        success: false,
        message: "画像解析中にエラーが発生しました。しばらく経ってから再度お試しください。",
        recognized_ingredients: [],
        conversion_metrics: {}
      }, status: :internal_server_error
    end
  end

  private

  def set_user_ingredient
    @user_ingredient = UserIngredient.find(params[:id])
  end

  def authorize_user!
    unless @user_ingredient.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
    end
  end

  def user_ingredient_params
    params.require(:user_ingredient).permit(:ingredient_id, :quantity, :expiry_date)
  end

  def user_ingredient_update_params
    params.require(:user_ingredient).permit(:quantity, :expiry_date, :status)
  end

  # 画像認識用のメソッド
  def extract_image_files
    files = []

    # 単一画像の場合
    if params[:image].present?
      files << params[:image]
    end

    # 複数画像の場合（配列以外のケースも安全に正規化）
    if params[:images].present?
      # Array()で安全に配列化（ハッシュや単一要素も配列に変換）
      files.concat(Array(params[:images]))
    end

    files.compact.reject(&:blank?)  # nilと空文字列の両方を除去
  end

  def validate_image_file(file)
    # ファイルが存在するかチェック
    return "無効なファイルです" unless file.respond_to?(:read)

    # ファイル形式チェック（iOS/Android端末由来の画像も対応）
    allowed_types = %w[image/jpeg image/jpg image/png image/gif image/bmp image/webp image/heic]
    unless allowed_types.include?(file.content_type)
      return "対応していないファイル形式です。JPEG、PNG、GIF、BMP、WebP、HEICに対応しています。"
    end

    # ファイルサイズチェック（20MB制限）
    if file.size > 20.megabytes
      return "ファイルサイズが大きすぎます。20MB以下のファイルをアップロードしてください。"
    end

    # ファイルが空でないかチェック
    if file.size == 0
      return "ファイルが空です"
    end

    nil # エラーなし
  end
end
