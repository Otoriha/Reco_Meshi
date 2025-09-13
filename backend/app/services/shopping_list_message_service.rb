class ShoppingListMessageService
  def initialize(line_bot_service)
    @line_bot_service = line_bot_service
  end

  def generate_text_message(shopping_list)
    message = "🛒 #{shopping_list.display_title}\n\n"
    
    if shopping_list.recipe
      message += "📖 レシピ: #{shopping_list.recipe.title}\n\n"
    end
    
    unchecked_items = shopping_list.shopping_list_items.unchecked.includes(:ingredient)
    checked_items = shopping_list.shopping_list_items.checked.includes(:ingredient)
    
    if unchecked_items.any?
      message += "📝 未購入の商品:\n"
      unchecked_items.each do |item|
        ingredient_name = item.ingredient&.name || "不明な食材"
        quantity = item.quantity.present? ? " #{item.quantity}" : ""
        unit = item.unit.present? ? "#{item.unit}" : ""
        message += "☐ #{ingredient_name}#{quantity}#{unit}\n"
      end
      message += "\n"
    end
    
    if checked_items.any?
      message += "✅ 購入済み:\n"
      checked_items.each do |item|
        ingredient_name = item.ingredient&.name || "不明な食材"
        quantity = item.quantity.present? ? " #{item.quantity}" : ""
        unit = item.unit.present? ? "#{item.unit}" : ""
        message += "☑ #{ingredient_name}#{quantity}#{unit}\n"
      end
      message += "\n"
    end
    
    progress = shopping_list.completion_percentage
    message += "進捗: #{progress}% (#{shopping_list.shopping_list_items.checked.count}/#{shopping_list.total_items_count})\n\n"
    
    message += "詳細な管理はLIFFアプリをご利用ください！"
    
    @line_bot_service.create_text_message(message)
  end

  def generate_flex_message(shopping_list)
    # Flexメッセージのバブルを生成
    bubble = generate_checklist_bubble(shopping_list)
    
    # altTextを400文字以内に制限
    alt_text = generate_alt_text(shopping_list)
    
    @line_bot_service.create_flex_message(alt_text, bubble)
  rescue => e
    Rails.logger.error "Flex shopping list message generation failed: #{e.message}"
    # フォールバック: テキストメッセージを返す
    generate_text_message(shopping_list)
  end

  def generate_checklist_bubble(shopping_list)
    unchecked_items = shopping_list.shopping_list_items.unchecked.includes(:ingredient).limit(10)
    checked_items = shopping_list.shopping_list_items.checked.includes(:ingredient).limit(5)
    
    contents = []
    
    # ヘッダー
    contents << {
      type: "text",
      text: shopping_list.display_title,
      weight: "bold",
      size: "lg",
      wrap: true
    }
    
    # レシピ情報
    if shopping_list.recipe
      contents << {
        type: "text",
        text: "📖 #{shopping_list.recipe.title}",
        size: "sm",
        color: "#666666",
        margin: "sm",
        wrap: true
      }
    end
    
    # 進捗情報
    progress = shopping_list.completion_percentage
    contents << {
      type: "text",
      text: "進捗: #{progress}% (#{shopping_list.shopping_list_items.checked.count}/#{shopping_list.total_items_count})",
      size: "sm",
      color: "#666666",
      margin: "md"
    }
    
    # 未購入アイテム
    if unchecked_items.any?
      contents << {
        type: "text",
        text: "📝 未購入の商品",
        weight: "bold",
        size: "md",
        margin: "lg"
      }
      
      unchecked_items.each do |item|
        ingredient_name = item.ingredient&.name || "不明な食材"
        quantity = item.quantity.present? ? " #{item.quantity}" : ""
        unit = item.unit.present? ? "#{item.unit}" : ""
        
        contents << create_checkable_item_box(
          "☐ #{ingredient_name}#{quantity}#{unit}",
          "check_item:#{shopping_list.id}:#{item.id}",
          item.is_checked
        )
      end
    end
    
    # 購入済みアイテム（最大5件）
    if checked_items.any?
      contents << {
        type: "text",
        text: "✅ 購入済み",
        weight: "bold",
        size: "md",
        margin: "lg"
      }
      
      checked_items.each do |item|
        ingredient_name = item.ingredient&.name || "不明な食材"
        quantity = item.quantity.present? ? " #{item.quantity}" : ""
        unit = item.unit.present? ? "#{item.unit}" : ""
        
        contents << create_checkable_item_box(
          "☑ #{ingredient_name}#{quantity}#{unit}",
          "check_item:#{shopping_list.id}:#{item.id}",
          item.is_checked
        )
      end
    end
    
    # アイテム数制限の警告
    total_items = shopping_list.total_items_count
    displayed_items = unchecked_items.count + checked_items.count
    if total_items > displayed_items
      contents << {
        type: "text",
        text: "...他#{total_items - displayed_items}件",
        size: "sm",
        color: "#999999",
        margin: "sm"
      }
    end
    
    # バブル構造
    bubble = {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: contents
      },
      footer: {
        type: "box",
        layout: "vertical",
        spacing: "sm",
        contents: create_footer_buttons(shopping_list)
      }
    }
    
    bubble
  end

  private

  def create_checkable_item_box(text, postback_data, is_checked)
    {
      type: "box",
      layout: "horizontal",
      contents: [
        {
          type: "text",
          text: text,
          size: "sm",
          color: is_checked ? "#999999" : "#333333",
          flex: 1,
          wrap: true
        }
      ],
      action: {
        type: "postback",
        data: postback_data
      },
      margin: "sm",
      paddingAll: "8px",
      backgroundColor: is_checked ? "#f5f5f5" : "#ffffff",
      cornerRadius: "4px"
    }
  end

  def create_footer_buttons(shopping_list)
    buttons = []
    
    # LIFFで詳細を見るボタン
    buttons << {
      type: "button",
      style: "link",
      height: "sm",
      action: {
        type: "uri",
        label: "詳細をLIFFで見る",
        uri: @line_bot_service.generate_liff_url("/shopping-lists/#{shopping_list.id}")
      }
    }
    
    # リスト完了ボタン（未完了の場合のみ）
    if shopping_list.unchecked_items_count > 0
      buttons << {
        type: "button",
        style: "primary",
        height: "sm",
        color: "#42A5F5",
        action: {
          type: "postback",
          label: "買い物完了",
          data: "complete_list:#{shopping_list.id}"
        }
      }
    end
    
    buttons
  end

  def generate_alt_text(shopping_list)
    base_text = "買い物リスト: #{shopping_list.display_title}"
    
    if shopping_list.recipe
      base_text += " (#{shopping_list.recipe.title})"
    end
    
    unchecked_count = shopping_list.unchecked_items_count
    if unchecked_count > 0
      base_text += " - 未購入#{unchecked_count}件"
    else
      base_text += " - 完了"
    end
    
    # 400文字制限
    base_text.length > 400 ? base_text[0, 397] + "..." : base_text
  end
end