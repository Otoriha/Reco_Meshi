class LineRichMenuService

  def initialize
    @client = Line::Bot::Client.new do |config|
      config.channel_secret = Rails.application.credentials.line_channel_secret || ENV['LINE_CHANNEL_SECRET']
      config.channel_token = Rails.application.credentials.line_channel_access_token || ENV['LINE_CHANNEL_ACCESS_TOKEN']
    end
  end

  def create_rich_menu
    rich_menu_object = create_rich_menu_object
    response = @client.create_rich_menu(rich_menu_object)
    
    if response.code == '200'
      rich_menu_id = JSON.parse(response.body)['richMenuId']
      Rails.logger.info "Rich menu created with ID: #{rich_menu_id}"
      rich_menu_id
    else
      Rails.logger.error "Failed to create rich menu: #{response.body}"
      nil
    end
  end

  def set_rich_menu_image(rich_menu_id, image_path)
    File.open(image_path, 'rb') do |file|
      response = @client.create_rich_menu_image(rich_menu_id, file)
      
      if response.code == '200'
        Rails.logger.info "Rich menu image uploaded for ID: #{rich_menu_id}"
        true
      else
        Rails.logger.error "Failed to upload rich menu image: #{response.body}"
        false
      end
    end
  end

  def set_default_rich_menu(rich_menu_id)
    response = @client.set_default_rich_menu(rich_menu_id)
    
    if response.code == '200'
      Rails.logger.info "Default rich menu set to: #{rich_menu_id}"
      true
    else
      Rails.logger.error "Failed to set default rich menu: #{response.body}"
      false
    end
  end

  def get_rich_menu_list
    response = @client.get_rich_menu_list
    
    if response.code == '200'
      JSON.parse(response.body)['richmenus']
    else
      Rails.logger.error "Failed to get rich menu list: #{response.body}"
      []
    end
  end

  def delete_rich_menu(rich_menu_id)
    response = @client.delete_rich_menu(rich_menu_id)
    
    if response.code == '200'
      Rails.logger.info "Rich menu deleted: #{rich_menu_id}"
      true
    else
      Rails.logger.error "Failed to delete rich menu: #{response.body}"
      false
    end
  end

  def get_default_rich_menu_id
    response = @client.get_default_rich_menu
    
    if response.code == '200'
      JSON.parse(response.body)['richMenuId']
    else
      Rails.logger.info "No default rich menu set"
      nil
    end
  end

  def cancel_default_rich_menu
    response = @client.cancel_default_rich_menu
    
    if response.code == '200'
      Rails.logger.info "Default rich menu cancelled"
      true
    else
      Rails.logger.error "Failed to cancel default rich menu: #{response.body}"
      false
    end
  end

  def cleanup_all_rich_menus
    rich_menus = get_rich_menu_list
    
    rich_menus.each do |menu|
      delete_rich_menu(menu['richMenuId'])
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
    
    {
      size: {
        width: 2500,
        height: 1686
      },
      selected: false,
      name: "レコめしメニュー",
      chatBarText: "メニューを開く",
      areas: [
        {
          bounds: {
            x: 0,
            y: 0,
            width: 833,
            height: 843
          },
          action: {
            type: "postback",
            data: "recipe_request",
            displayText: "レシピを提案して"
          }
        },
        {
          bounds: {
            x: 833,
            y: 0,
            width: 834,
            height: 843
          },
          action: {
            type: "postback",
            data: "ingredients_list",
            displayText: "食材リストを見せて"
          }
        },
        {
          bounds: {
            x: 1667,
            y: 0,
            width: 833,
            height: 843
          },
          action: {
            type: "uri",
            uri: "https://liff.line.me/#{ENV['LIFF_ID']}"
          }
        },
        {
          bounds: {
            x: 0,
            y: 843,
            width: 1250,
            height: 843
          },
          action: {
            type: "uri",
            uri: ENV['FRONTEND_URL'] || "https://reco-meshiweb.vercel.app"
          }
        },
        {
          bounds: {
            x: 1250,
            y: 843,
            width: 1250,
            height: 843
          },
          action: {
            type: "postback",
            data: "help",
            displayText: "ヘルプ"
          }
        }
      ]
    }
  end

  attr_reader :client
end