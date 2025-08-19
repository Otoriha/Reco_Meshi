class LineRichMenuService

  def initialize
    # V2 API対応: Rich Menu APIもV2クライアントを使用
    @channel_token = Rails.application.credentials.line_channel_access_token || ENV['LINE_CHANNEL_ACCESS_TOKEN']
    @client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: @channel_token
    )
    # ApiBlobClient for image operations
    @blob_client = Line::Bot::V2::MessagingApi::ApiBlobClient.new(
      channel_access_token: @channel_token
    )
  end

  def create_rich_menu
    rich_menu_request = create_rich_menu_object
    response = @client.create_rich_menu(rich_menu_request: rich_menu_request)
    
    if response.rich_menu_id
      Rails.logger.info "Rich menu created with ID: #{response.rich_menu_id}"
      response.rich_menu_id
    else
      Rails.logger.error "Failed to create rich menu"
      nil
    end
  rescue => e
    Rails.logger.error "Failed to create rich menu: #{e.message}"
    nil
  end

  def set_rich_menu_image(rich_menu_id, image_path)
    File.open(image_path, 'rb') do |file|
      # V2 API: Rich Menu Image設定はApiBlobClientで実行（content_typeは不要）
      @blob_client.set_rich_menu_image(rich_menu_id: rich_menu_id, body: file.read)
      Rails.logger.info "Rich menu image uploaded for ID: #{rich_menu_id}"
      true
    end
  rescue => e
    Rails.logger.error "Failed to upload rich menu image: #{e.message}"
    false
  end

  def set_default_rich_menu(rich_menu_id)
    @client.set_default_rich_menu(rich_menu_id: rich_menu_id)
    Rails.logger.info "Default rich menu set to: #{rich_menu_id}"
    true
  rescue => e
    Rails.logger.error "Failed to set default rich menu: #{e.message}"
    false
  end

  def get_rich_menu_list
    response = @client.get_rich_menu_list
    response.richmenus || []
  rescue => e
    Rails.logger.error "Failed to get rich menu list: #{e.message}"
    []
  end

  def delete_rich_menu(rich_menu_id)
    @client.delete_rich_menu(rich_menu_id: rich_menu_id)
    Rails.logger.info "Rich menu deleted: #{rich_menu_id}"
    true
  rescue => e
    Rails.logger.error "Failed to delete rich menu: #{e.message}"
    false
  end

  def get_default_rich_menu_id
    response = @client.get_default_rich_menu_id
    response.rich_menu_id
  rescue => e
    Rails.logger.info "No default rich menu set: #{e.message}"
    nil
  end

  def cancel_default_rich_menu
    @client.cancel_default_rich_menu
    Rails.logger.info "Default rich menu cancelled"
    true
  rescue => e
    Rails.logger.error "Failed to cancel default rich menu: #{e.message}"
    false
  end

  def cleanup_all_rich_menus
    rich_menus = get_rich_menu_list
    
    rich_menus.each do |menu|
      delete_rich_menu(menu.rich_menu_id)
    end
    
    Rails.logger.info "Cleaned up #{rich_menus.count} rich menus"
  end

  def setup_default_rich_menu
    # 既存のリッチメニューをクリーンアップ
    cleanup_all_rich_menus
    
    # 新しいリッチメニューを作成
    rich_menu_id = create_rich_menu
    return false unless rich_menu_id
    
    # リッチメニュー画像を設定（将来的に実装）
    # image_path = Rails.root.join('app', 'assets', 'images', 'rich_menu.png')
    # return false unless set_rich_menu_image(rich_menu_id, image_path)
    
    # デフォルトに設定
    set_default_rich_menu(rich_menu_id)
  end

  private

  def create_rich_menu_object
    raise "LIFF_ID environment variable is required" unless ENV['LIFF_ID']
    
    # V2 API: RichMenuRequest オブジェクトを作成
    Line::Bot::V2::MessagingApi::RichMenuRequest.new(
      size: Line::Bot::V2::MessagingApi::RichMenuSize.new(width: 2500, height: 1686),
      selected: false,
      name: "レコめしメニュー",
      chat_bar_text: "メニューを開く",
      areas: [
        Line::Bot::V2::MessagingApi::RichMenuArea.new(
          bounds: Line::Bot::V2::MessagingApi::RichMenuBounds.new(x: 0, y: 0, width: 833, height: 843),
          action: Line::Bot::V2::MessagingApi::PostbackAction.new(data: "recipe_request", display_text: "レシピを提案して")
        ),
        Line::Bot::V2::MessagingApi::RichMenuArea.new(
          bounds: Line::Bot::V2::MessagingApi::RichMenuBounds.new(x: 833, y: 0, width: 834, height: 843),
          action: Line::Bot::V2::MessagingApi::PostbackAction.new(data: "ingredients_list", display_text: "食材リストを見せて")
        ),
        Line::Bot::V2::MessagingApi::RichMenuArea.new(
          bounds: Line::Bot::V2::MessagingApi::RichMenuBounds.new(x: 1667, y: 0, width: 833, height: 843),
          action: Line::Bot::V2::MessagingApi::URIAction.new(uri: "https://liff.line.me/#{ENV['LIFF_ID']}")
        ),
        Line::Bot::V2::MessagingApi::RichMenuArea.new(
          bounds: Line::Bot::V2::MessagingApi::RichMenuBounds.new(x: 0, y: 843, width: 1250, height: 843),
          action: Line::Bot::V2::MessagingApi::URIAction.new(uri: ENV['FRONTEND_URL'] || "https://reco-meshiweb.vercel.app")
        ),
        Line::Bot::V2::MessagingApi::RichMenuArea.new(
          bounds: Line::Bot::V2::MessagingApi::RichMenuBounds.new(x: 1250, y: 843, width: 1250, height: 843),
          action: Line::Bot::V2::MessagingApi::PostbackAction.new(data: "help", display_text: "ヘルプ")
        )
      ]
    )
  end

  attr_reader :client
end