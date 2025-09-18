namespace :line do
  desc "Setup LINE Bot rich menu"
  task setup_rich_menu: :environment do
    puts "Setting up LINE Bot rich menu..."

    service = LineRichMenuService.new

    if service.setup_default_rich_menu
      puts "✅ Rich menu setup completed successfully!"
    else
      puts "❌ Rich menu setup failed!"
      exit 1
    end
  end

  desc "List all rich menus"
  task list_rich_menus: :environment do
    puts "Listing all rich menus..."

    service = LineRichMenuService.new
    rich_menus = service.get_rich_menu_list

    if rich_menus.empty?
      puts "No rich menus found."
    else
      puts "Found #{rich_menus.count} rich menu(s):"
      rich_menus.each_with_index do |menu, index|
        puts "#{index + 1}. ID: #{menu['richMenuId']}"
        puts "   Name: #{menu['name']}"
        puts "   Chat Bar Text: #{menu['chatBarText']}"
        puts "   Selected: #{menu['selected']}"
        puts ""
      end
    end
  end

  desc "Get default rich menu"
  task get_default_rich_menu: :environment do
    puts "Getting default rich menu..."

    service = LineRichMenuService.new
    default_menu_id = service.get_default_rich_menu_id

    if default_menu_id
      puts "✅ Default rich menu ID: #{default_menu_id}"
    else
      puts "ℹ️  No default rich menu is set."
    end
  end

  desc "Delete all rich menus"
  task cleanup_rich_menus: :environment do
    puts "Cleaning up all rich menus..."

    service = LineRichMenuService.new
    service.cleanup_all_rich_menus

    puts "✅ All rich menus have been deleted!"
  end

  desc "Cancel default rich menu"
  task cancel_default_rich_menu: :environment do
    puts "Cancelling default rich menu..."

    service = LineRichMenuService.new

    if service.cancel_default_rich_menu
      puts "✅ Default rich menu cancelled successfully!"
    else
      puts "❌ Failed to cancel default rich menu!"
    end
  end

  desc "Test LINE Bot connection"
  task test_connection: :environment do
    puts "Testing LINE Bot connection..."

    begin
      service = LineBotService.new
      # プロフィールAPIを使用して接続テスト（実際のユーザーIDが必要）
      puts "✅ LINE Bot service initialized successfully!"
      puts "Channel Secret: #{ENV['LINE_CHANNEL_SECRET'] ? 'Set' : 'Not set'}"
      puts "Channel Access Token: #{ENV['LINE_CHANNEL_ACCESS_TOKEN'] ? 'Set' : 'Not set'}"
      puts "LIFF ID: #{ENV['LIFF_ID'] || 'Not set'}"
    rescue => e
      puts "❌ Connection test failed: #{e.message}"
      exit 1
    end
  end

  desc "Show LINE Bot configuration"
  task show_config: :environment do
    puts "LINE Bot Configuration:"
    puts "========================"
    puts "Channel Secret: #{ENV['LINE_CHANNEL_SECRET'] ? 'Set (hidden)' : '❌ Not set'}"
    puts "Channel Access Token: #{ENV['LINE_CHANNEL_ACCESS_TOKEN'] ? 'Set (hidden)' : '❌ Not set'}"
    puts "LIFF ID: #{ENV['LIFF_ID'] || '❌ Not set'}"
    puts "Frontend URL: #{ENV['FRONTEND_URL'] || '❌ Not set'}"
    puts "LIFF URL: #{ENV['LIFF_URL'] || '❌ Not set'}"
    puts ""
    puts "Webhook URL should be: #{Rails.application.routes.url_helpers.api_v1_line_webhook_url rescue 'Unable to generate URL'}"
    puts ""

    if ENV["LINE_CHANNEL_SECRET"].blank? || ENV["LINE_CHANNEL_ACCESS_TOKEN"].blank?
      puts "⚠️  Warning: LINE Bot credentials are not properly configured!"
      puts "Please set LINE_CHANNEL_SECRET and LINE_CHANNEL_ACCESS_TOKEN in your environment variables."
    else
      puts "✅ LINE Bot credentials are configured!"
    end
  end
end
