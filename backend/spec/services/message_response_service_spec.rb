require 'rails_helper'

RSpec.describe MessageResponseService do
  let(:line_bot_service) { instance_double(LineBotService) }
  let(:service) { described_class.new(line_bot_service) }
  let(:mock_message) { instance_double('Message') }

  before do
    allow(line_bot_service).to receive(:create_text_message).and_return(mock_message)
  end

  describe '#generate_response' do
    context 'when command is :greeting' do
      it 'creates a greeting message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('こんにちは！レコめしへようこそ🍽️')
        )
        
        service.generate_response(:greeting)
      end

      it 'includes usage instructions in greeting' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('使えるコマンド')
        )
        
        service.generate_response(:greeting)
      end
    end

    context 'when command is :recipe' do
      it 'creates a recipe suggestion message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('今ある食材でのレシピ提案')
        )
        
        service.generate_response(:recipe)
      end

      it 'includes mock ingredients and recipe' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('豚肉と野菜の炒め物')
        )
        
        service.generate_response(:recipe)
      end

      it 'mentions sample data disclaimer' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('現在はサンプルデータを表示しています')
        )
        
        service.generate_response(:recipe)
      end
    end

    context 'when command is :ingredients' do
      it 'creates an ingredients list message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('現在の食材リスト')
        )
        
        service.generate_response(:ingredients)
      end

      it 'includes mock ingredients with quantities and expiry dates' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_matching(/玉ねぎ.*2個.*3日後/)
        )
        
        service.generate_response(:ingredients)
      end

      it 'mentions LIFF app for detailed management' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('LIFFアプリをご利用ください')
        )
        
        service.generate_response(:ingredients)
      end
    end

    context 'when command is :shopping' do
      it 'creates a shopping list message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('買い物リスト')
        )
        
        service.generate_response(:shopping)
      end

      it 'includes mock shopping items with reasons' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('牛乳').and(
            a_string_including('冷蔵庫にありません')
          )
        )
        
        service.generate_response(:shopping)
      end

      it 'mentions future recipe ingredient integration' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('レシピに必要な食材も自動で追加予定')
        )
        
        service.generate_response(:shopping)
      end
    end

    context 'when command is :help' do
      it 'creates a help message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('レコめしの使い方')
        )
        
        service.generate_response(:help)
      end

      it 'includes basic features explanation' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('基本機能').and(
            a_string_including('冷蔵庫の写真を送信')
          )
        )
        
        service.generate_response(:help)
      end

      it 'includes text commands list' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('テキストコマンド').and(
            a_string_including('「レシピ」「料理」')
          )
        )
        
        service.generate_response(:help)
      end
    end

    context 'when command is :unknown' do
      it 'creates an unknown message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('メッセージの内容を理解できませんでした')
        )
        
        service.generate_response(:unknown)
      end

      it 'suggests photo upload and available commands' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('冷蔵庫の写真を送っていただければ').and(
            a_string_including('以下のコマンドもご利用いただけます')
          )
        )
        
        service.generate_response(:unknown)
      end
    end

    context 'when command is nil or invalid' do
      it 'creates an unknown message for nil command' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('メッセージの内容を理解できませんでした')
        )
        
        service.generate_response(nil)
      end

      it 'creates an unknown message for invalid command' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('メッセージの内容を理解できませんでした')
        )
        
        service.generate_response(:invalid_command)
      end
    end

    context 'with user_id parameter' do
      it 'accepts user_id parameter without error' do
        expect {
          service.generate_response(:greeting, 'user123')
        }.not_to raise_error
      end
    end
  end

  describe 'message content validation' do
    it 'greeting message contains welcome text' do
      expect(line_bot_service).to receive(:create_text_message) do |message|
        expect(message).to include('ようこそ')
        expect(message).to include('📝 使えるコマンド')
        mock_message
      end
      
      service.generate_response(:greeting)
    end

    it 'recipe message contains cooking emoji and time' do
      expect(line_bot_service).to receive(:create_text_message) do |message|
        expect(message).to include('🍳')
        expect(message).to include('約15分')
        mock_message
      end
      
      service.generate_response(:recipe)
    end

    it 'ingredients message contains proper formatting' do
      expect(line_bot_service).to receive(:create_text_message) do |message|
        expect(message).to include('📝')
        expect(message).to include('• ')
        expect(message).to include('消費期限:')
        mock_message
      end
      
      service.generate_response(:ingredients)
    end
  end
end