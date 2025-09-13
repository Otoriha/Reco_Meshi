require 'rails_helper'

RSpec.describe ShoppingListMessageService, type: :service do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user) }
  let(:shopping_list) { create(:shopping_list, user: user, recipe: recipe) }
  let(:ingredient1) { create(:ingredient, name: "玉ねぎ") }
  let(:ingredient2) { create(:ingredient, name: "人参") }
  let(:line_bot_service) { instance_double(LineBotService) }
  let(:service) { described_class.new(line_bot_service) }

  before do
    create(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient1, quantity: 2, unit: "個", is_checked: false)
    create(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient2, quantity: 1, unit: "本", is_checked: true)
    
    allow(line_bot_service).to receive(:create_text_message)
    allow(line_bot_service).to receive(:create_flex_message)
    allow(line_bot_service).to receive(:generate_liff_url).and_return("https://liff.line.me/test/shopping-lists/#{shopping_list.id}")
  end

  describe '#generate_text_message' do
    it 'テキスト形式の買い物リストメッセージを生成する' do
      expect(line_bot_service).to receive(:create_text_message).with(kind_of(String))
      
      service.generate_text_message(shopping_list)
    end

    it '未購入と購入済みの商品を適切に表示する' do
      allow(line_bot_service).to receive(:create_text_message) do |message|
        expect(message).to include("☐ 玉ねぎ 2個")
        expect(message).to include("☑ 人参 1本")
        expect(message).to include("進捗: 50.0%")
      end
      
      service.generate_text_message(shopping_list)
    end
  end

  describe '#generate_flex_message' do
    it 'Flexメッセージを生成する' do
      expect(line_bot_service).to receive(:create_flex_message).with(kind_of(String), kind_of(Hash))
      
      service.generate_flex_message(shopping_list)
    end

    it 'エラーが発生した場合はテキストメッセージにフォールバックする' do
      allow(service).to receive(:generate_checklist_bubble).and_raise(StandardError, "Test error")
      expect(service).to receive(:generate_text_message).with(shopping_list)
      expect(Rails.logger).to receive(:error)
      
      service.generate_flex_message(shopping_list)
    end
  end

  describe '#generate_checklist_bubble' do
    let(:bubble) { service.send(:generate_checklist_bubble, shopping_list) }

    it 'バブル構造を適切に生成する' do
      expect(bubble).to have_key(:type)
      expect(bubble[:type]).to eq("bubble")
      expect(bubble).to have_key(:body)
      expect(bubble).to have_key(:footer)
    end

    it 'タイトルとレシピ情報を含む' do
      body_contents = bubble[:body][:contents]
      title_content = body_contents.find { |content| content[:text]&.include?(shopping_list.display_title) }
      recipe_content = body_contents.find { |content| content[:text]&.include?(recipe.title) }
      
      expect(title_content).to be_present
      expect(recipe_content).to be_present
    end

    it 'フッターにLIFFリンクボタンを含む' do
      footer_contents = bubble[:footer][:contents]
      liff_button = footer_contents.find { |content| content[:action][:type] == "uri" }
      
      expect(liff_button).to be_present
      expect(liff_button[:action][:uri]).to include("shopping-lists/#{shopping_list.id}")
    end
  end

  describe '#generate_alt_text' do
    it 'altTextを400文字以内で生成する' do
      alt_text = service.send(:generate_alt_text, shopping_list)
      
      expect(alt_text.length).to be <= 400
      expect(alt_text).to include(shopping_list.display_title)
    end

    it 'レシピ情報を含む場合は適切に表示する' do
      alt_text = service.send(:generate_alt_text, shopping_list)
      
      expect(alt_text).to include(recipe.title)
    end

    it '400文字を超える場合は省略記号を付ける' do
      long_title = "a" * 500
      allow(shopping_list).to receive(:display_title).and_return(long_title)
      
      alt_text = service.send(:generate_alt_text, shopping_list)
      
      expect(alt_text.length).to eq(400)
      expect(alt_text).to end_with("...")
    end
  end
end