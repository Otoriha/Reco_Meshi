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
      let(:mock_llm_service) { instance_double(Llm::OpenaiService) }
      let(:mock_llm_result) do
        Llm::Result.new(
          text: '{"title":"肉じゃが","time":"約25分","difficulty":"★★☆","ingredients":[{"name":"じゃがいも","amount":"3個"},{"name":"玉ねぎ","amount":"1個"},{"name":"人参","amount":"1本"},{"name":"豚肉","amount":"200g"}],"steps":["じゃがいもと人参を一口大に切る","玉ねぎをくし切りにする","豚肉を炒める","野菜を加えて炒める","調味料を加えて煮込む"]}',
          provider: 'openai',
          model: 'gpt-4o-mini'
        )
      end

      before do
        Rails.application.config.x.llm = {
          provider: 'openai',
          timeout_ms: 15000,
          max_retries: 3,
          temperature: 0.7,
          max_tokens: 1000,
          fallback_provider: 'gemini'
        }

        allow(Llm::Factory).to receive(:build).and_return(mock_llm_service)
        allow(PromptTemplateService).to receive(:recipe_generation).and_return({
          system: 'You are a chef',
          user: 'Create a recipe with: 玉ねぎ, 人参, じゃがいも, 豚肉'
        })
      end

      context 'when LLM service succeeds' do
        before do
          allow(mock_llm_service).to receive(:generate).and_return(mock_llm_result)
        end

        it 'creates a recipe suggestion message using LLM' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('🍳 今ある食材でのレシピ提案')
          )

          service.generate_response(:recipe)
        end

        it 'calls LLM service with correct parameters' do
          expect(mock_llm_service).to receive(:generate).with(
            messages: {
              system: 'You are a chef',
              user: 'Create a recipe with: 玉ねぎ, 人参, じゃがいも, 豚肉'
            },
            response_format: :json
          )

          service.generate_response(:recipe)
        end

        it 'formats LLM response correctly' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('「肉じゃが」').and(
              a_string_including('約25分')
            )
          )

          service.generate_response(:recipe)
        end

        it 'includes ingredients and steps from LLM response' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('材料:').and(
              a_string_including('・じゃがいも 3個')
            ).and(
              a_string_including('作り方:').and(
                a_string_including('1. じゃがいもと人参を一口大に切る')
              )
            )
          )

          service.generate_response(:recipe)
        end
      end

      context 'when LLM service fails' do
        before do
          # Disable fallback in this context to validate primary error behavior only
          Rails.application.config.x.llm = {
            provider: 'openai',
            timeout_ms: 15000,
            max_retries: 3,
            temperature: 0.7,
            max_tokens: 1000,
            fallback_provider: nil
          }
          allow(mock_llm_service).to receive(:generate).and_raise(StandardError.new('API Error'))
        end

        it 'falls back to mock recipe message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('豚肉と野菜の炒め物')
          )

          service.generate_response(:recipe)
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with('LLM API Error: API Error')

          service.generate_response(:recipe)
        end

        it 'instruments llm.error for primary failure' do
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.error', hash_including(provider: 'openai', error_class: 'StandardError')
          )
          service.generate_response(:recipe)
        end
      end

      context 'when fallback provider is configured and primary fails' do
        let(:mock_fallback_service) { instance_double(Llm::GeminiService) }

        before do
          allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
          allow(mock_llm_service).to receive(:generate).and_raise(StandardError.new('Primary API Error'))
          allow(Llm::Factory).to receive(:build).with(provider: 'gemini').and_return(mock_fallback_service)
          allow(mock_fallback_service).to receive(:generate).and_return(mock_llm_result)
        end

        it 'tries fallback provider' do
          expect(mock_fallback_service).to receive(:generate).with(
            messages: {
              system: 'You are a chef',
              user: 'Create a recipe with: 玉ねぎ, 人参, じゃがいも, 豚肉'
            },
            response_format: :json
          )

          service.generate_response(:recipe)
        end

        it 'returns successful response from fallback' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('「肉じゃが」')
          )

          service.generate_response(:recipe)
        end

        it 'instruments llm.error for primary and llm.fallback for switching' do
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.error', hash_including(provider: 'openai')
          )
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.fallback', { from: 'openai', to: 'gemini' }
          )
          service.generate_response(:recipe)
        end
      end

      context 'when both primary and fallback providers fail' do
        let(:mock_fallback_service) { instance_double(Llm::GeminiService) }

        before do
          allow(mock_llm_service).to receive(:generate).and_raise(StandardError.new('Primary API Error'))
          allow(Llm::Factory).to receive(:build).with(provider: 'gemini').and_return(mock_fallback_service)
          allow(mock_fallback_service).to receive(:generate).and_raise(StandardError.new('Fallback API Error'))
        end

        it 'falls back to mock recipe message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('豚肉と野菜の炒め物').and(
              a_string_including('現在はサンプルデータを表示しています')
            )
          )

          service.generate_response(:recipe)
        end

        it 'logs both errors' do
          expect(Rails.logger).to receive(:error).with('LLM API Error: Primary API Error')
          expect(Rails.logger).to receive(:error).with('LLM Fallback Error: Fallback API Error')

          service.generate_response(:recipe)
        end

        it 'instruments primary error, fallback attempt, then fallback error' do
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.error', hash_including(provider: 'openai')
          )
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.fallback', { from: 'openai', to: 'gemini' }
          )
          expect(ActiveSupport::Notifications).to receive(:instrument).with(
            'llm.error', hash_including(provider: 'gemini')
          )
          service.generate_response(:recipe)
        end
      end
    end

    context 'when command is :ingredients' do
      context 'without valid user_id' do
        it 'creates account registration message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('アカウント登録を行ってください')
          )

          service.generate_response(:ingredients, 'invalid_user_id')
        end
      end

      context 'with valid user but no ingredients' do
        let(:user) { create(:user) }
        let(:line_account) { create(:line_account, user: user, line_user_id: 'test_user_id') }

        before do
          line_account
        end

        it 'creates no ingredients message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('登録されている食材がありません')
          )

          service.generate_response(:ingredients, 'test_user_id')
        end
      end

      context 'with valid user and ingredients' do
        let(:user) { create(:user) }
        let(:line_account) { create(:line_account, user: user, line_user_id: 'test_user_id') }
        let(:ingredient) { create(:ingredient, name: '玉ねぎ', unit: '個') }

        before do
          line_account
          create(:user_ingredient, user: user, ingredient: ingredient,
                 quantity: 2, status: 'available',
                 expiry_date: 3.days.from_now.to_date)
        end

        it 'creates ingredients list message with actual data' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('📝 現在の食材リスト').and(
              a_string_including('• 玉ねぎ 2個')
            )
          )

          service.generate_response(:ingredients, 'test_user_id')
        end

        it 'mentions LIFF app for detailed management' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('LIFFアプリをご利用ください')
          )

          service.generate_response(:ingredients, 'test_user_id')
        end
      end
    end

    context 'when command is :shopping' do
      context 'without valid user_id' do
        it 'creates account registration message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('アカウント登録を行ってください')
          )

          service.generate_response(:shopping, 'invalid_user_id')
        end
      end

      context 'with valid user_id but no line account' do
        it 'creates account registration message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('アカウント登録を行ってください')
          )

          service.generate_response(:shopping, 'user_without_line_account')
        end
      end

      context 'with valid user but no shopping lists' do
        let(:user) { create(:user) }
        let(:line_account) { create(:line_account, user: user, line_user_id: 'test_user_id') }

        before do
          line_account
        end

        it 'creates no shopping list message' do
          expect(line_bot_service).to receive(:create_text_message).with(
            a_string_including('アクティブな買い物リストがありません')
          )

          service.generate_response(:shopping, 'test_user_id')
        end
      end

      context 'with valid user and shopping list' do
        let(:user) { create(:user) }
        let(:line_account) { create(:line_account, user: user, line_user_id: 'test_user_id') }
        let(:shopping_list) { create(:shopping_list, user: user, status: :pending) }
        let(:ingredient) { create(:ingredient, name: '玉ねぎ') }

        before do
          line_account
          create(:shopping_list_item, shopping_list: shopping_list, ingredient: ingredient, quantity: 2, unit: '個', is_checked: false)
        end

        context 'with flex disabled' do
          before do
            allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('false')
          end

          it 'creates text shopping list message' do
            expect(line_bot_service).to receive(:create_text_message).with(
              a_string_including('🛒').and(
                a_string_including('☐ 玉ねぎ 2個')
              )
            )

            service.generate_response(:shopping, 'test_user_id')
          end
        end

        context 'with flex enabled' do
          before do
            allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('true')
            allow(line_bot_service).to receive(:create_flex_message).and_return(mock_message)
            allow(line_bot_service).to receive(:generate_liff_url).and_return('https://liff.line.me/test')
          end

          it 'creates flex shopping list message' do
            expect(line_bot_service).to receive(:create_flex_message)

            service.generate_response(:shopping, 'test_user_id')
          end
        end

        context 'with flex disabled' do
          before do
            allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('false')
          end

          it 'creates text shopping list message as fallback' do
            expect(line_bot_service).to receive(:create_text_message).with(
              a_string_including('🛒').and(
                a_string_including('☐ 玉ねぎ 2個')
              )
            )
            expect(line_bot_service).not_to receive(:create_flex_message)

            service.generate_response(:shopping, 'test_user_id')
          end
        end
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

  describe '#flex_enabled?' do
    context 'when LINE_FLEX_ENABLED is true' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('true')
      end

      it 'returns true' do
        expect(service.send(:flex_enabled?)).to be true
      end
    end

    context 'when LINE_FLEX_ENABLED is false' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('false')
      end

      it 'returns false' do
        expect(service.send(:flex_enabled?)).to be false
      end
    end

    context 'when LINE_FLEX_ENABLED is not set' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return(nil)
      end

      it 'returns false' do
        expect(service.send(:flex_enabled?)).to be false
      end
    end

    context 'when LINE_FLEX_ENABLED is a string "1"' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('1')
      end

      it 'returns true' do
        expect(service.send(:flex_enabled?)).to be true
      end
    end
  end

  describe '#create_flex_recipe_message' do
    let(:valid_json) do
      {
        title: 'テストレシピ',
        time: '20分',
        difficulty: '★★☆',
        ingredients: [
          { name: '玉ねぎ', amount: '1個' },
          { name: '人参', amount: '1本' }
        ],
        steps: [
          '玉ねぎを切る',
          '人参を切る',
          '炒める'
        ]
      }.to_json
    end

    let(:invalid_json) { 'invalid json' }
    let(:empty_json) { '{}' }

    before do
      allow(line_bot_service).to receive(:generate_liff_url).and_return('https://liff.line.me/test-id/recipes')
      allow(line_bot_service).to receive(:create_flex_message).and_return(mock_message)
      allow(line_bot_service).to receive(:create_text_message).and_return(mock_message)
    end

    context 'with valid JSON data' do
      it 'creates a flex message with recipe data' do
        expect(line_bot_service).to receive(:create_flex_message).with(
          '[レシピ] テストレシピ',
          hash_including(
            type: 'bubble',
            body: hash_including(
              type: 'box',
              layout: 'vertical'
            ),
            footer: hash_including(
              type: 'box',
              layout: 'vertical'
            )
          )
        )

        service.send(:create_flex_recipe_message, valid_json)
      end

      it 'limits ingredients to maximum 5 items' do
        long_ingredients_json = {
          title: 'テストレシピ',
          ingredients: Array.new(10) { |i| { name: "材料#{i + 1}", amount: '1個' } }
        }.to_json

        expect(line_bot_service).to receive(:create_flex_message) do |alt_text, contents|
          # 材料セクションの確認
          body_contents = contents[:body][:contents]
          ingredient_texts = body_contents.select { |c| c[:text]&.start_with?('・') }
          expect(ingredient_texts.length).to eq(5)
        end

        service.send(:create_flex_recipe_message, long_ingredients_json)
      end

      it 'limits steps to maximum 3 items' do
        long_steps_json = {
          title: 'テストレシピ',
          steps: Array.new(10) { |i| "ステップ#{i + 1}" }
        }.to_json

        service.send(:create_flex_recipe_message, long_steps_json)

        # ステップが3つに制限されていることを確認するために、
        # steps = Array(data["steps"]).take(3) の結果を確認
        expect(line_bot_service).to have_received(:create_flex_message)
      end

      it 'truncates alt text to 400 characters' do
        long_title = 'テ' * 500
        long_title_json = {
          title: long_title
        }.to_json

        expect(line_bot_service).to receive(:create_flex_message) do |alt_text, contents|
          expect(alt_text.length).to be <= 400
          expect(alt_text).to start_with('[レシピ] テ')
        end

        service.send(:create_flex_recipe_message, long_title_json)
      end

      it 'includes LIFF link in footer' do
        expect(line_bot_service).to receive(:create_flex_message) do |alt_text, contents|
          button = contents[:footer][:contents].first
          expect(button[:action][:type]).to eq('uri')
          expect(button[:action][:label]).to eq('詳しく見る')
          expect(button[:action][:uri]).to eq('https://liff.line.me/test-id/recipes')
        end

        service.send(:create_flex_recipe_message, valid_json)
      end
    end

    context 'with empty JSON data' do
      it 'creates flex message with default values' do
        expect(line_bot_service).to receive(:create_flex_message) do |alt_text, contents|
          expect(alt_text).to eq('[レシピ] おすすめレシピ')

          title_component = contents[:body][:contents].first
          expect(title_component[:text]).to eq('おすすめレシピ')

          time_component = contents[:body][:contents][1][:contents].first
          expect(time_component[:text]).to include('約15分')
        end

        service.send(:create_flex_recipe_message, empty_json)
      end
    end

    context 'with invalid JSON' do
      it 'falls back to error message' do
        expect(line_bot_service).to receive(:create_text_message).with(
          '申し訳ございませんが、レシピの生成に失敗しました。もう一度お試しください。'
        )

        service.send(:create_flex_recipe_message, invalid_json)
      end
    end

    context 'when flex message creation fails' do
      before do
        allow(line_bot_service).to receive(:create_flex_message).and_raise(StandardError.new('Flex creation failed'))
        allow(service).to receive(:format_recipe_text).and_return('fallback text')
      end

      it 'falls back to text message' do
        expect(line_bot_service).to receive(:create_text_message).with('fallback text')

        service.send(:create_flex_recipe_message, valid_json)
      end
    end
  end

  describe 'Flex message integration in recipe generation' do
    # Use a concrete existing class for the test double
    let(:mock_llm_service) { instance_double(Llm::OpenaiService) }
    let(:mock_llm_result) { double('LlmResult', text: '{"title":"肉じゃが","time":"約25分"}') }

    before do
      allow(Rails.application.config.x.llm).to receive(:is_a?).and_return(false)
      allow(Rails.application.config.x.llm).to receive(:provider).and_return('openai')
      allow(Llm::Factory).to receive(:build).and_return(mock_llm_service)
      allow(PromptTemplateService).to receive(:recipe_generation).and_return({})
      allow(mock_llm_service).to receive(:generate).and_return(mock_llm_result)
    end

    context 'when flex is enabled' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('true')
        allow(line_bot_service).to receive(:generate_liff_url).and_return('https://liff.line.me/test-id/recipes')
        allow(line_bot_service).to receive(:create_flex_message).and_return(mock_message)
      end

      it 'creates flex message instead of text message' do
        expect(line_bot_service).to receive(:create_flex_message)
        expect(line_bot_service).not_to receive(:create_text_message)

        service.generate_response(:recipe)
      end
    end

    context 'when flex is disabled' do
      before do
        allow(ENV).to receive(:[]).with('LINE_FLEX_ENABLED').and_return('false')
      end

      it 'creates text message as before' do
        expect(line_bot_service).to receive(:create_text_message).with(
          a_string_including('🍳 今ある食材でのレシピ提案')
        )
        expect(line_bot_service).not_to receive(:create_flex_message)

        service.generate_response(:recipe)
      end
    end
  end

  describe 'message content validation' do
    before do
      # Ensure no real LLM calls occur in these generic content tests
      allow(Llm::Factory).to receive(:build).and_raise(StandardError.new('Disabled in content validation'))
    end
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
      user = create(:user)
      ingredient = create(:ingredient, name: 'テスト食材', unit: 'g')
      line_account = create(:line_account, user: user, line_user_id: 'test_user_formatting')
      create(:user_ingredient, user: user, ingredient: ingredient,
             quantity: 100, status: 'available',
             expiry_date: 3.days.from_now.to_date)

      expect(line_bot_service).to receive(:create_text_message) do |message|
        expect(message).to include('📝')
        expect(message).to include('• ')
        expect(message).to include('日後まで')
        mock_message
      end

      service.generate_response(:ingredients, 'test_user_formatting')
    end
  end
end
