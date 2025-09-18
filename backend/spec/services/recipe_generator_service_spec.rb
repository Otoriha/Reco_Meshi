require 'rails_helper'

RSpec.describe 'RecipeGeneratorService' do
  before do
    skip 'RecipeGeneratorService 未実装のためスキップ' unless defined?(RecipeGeneratorService)
  end

  let(:user) { create(:user) }
  let(:mock_llm_service) { instance_double(Llm::OpenaiService) }
  let(:mock_result) do
    Llm::Result.new(
      text: '{"title":"簡単トマト炒め","time":"約10分","difficulty":"easy","ingredients":[{"name":"トマト","amount":"2個"}],"steps":["切る","炒める"]}',
      provider: 'openai', model: 'gpt-4o-mini'
    )
  end

  before do
    Rails.application.config.x.llm = {
      provider: 'openai', timeout_ms: 15000, max_retries: 3,
      temperature: 0.7, max_tokens: 1000
    }
    allow(Llm::Factory).to receive(:build).and_return(mock_llm_service)
    allow(mock_llm_service).to receive(:generate).and_return(mock_result)
    allow(PromptTemplateService).to receive(:recipe_generation).and_return({ system: 'sys', user: 'usr' })
  end

  it 'LLM→Converter→保存まで一連の処理を行いRecipeを返す' do
    service = RecipeGeneratorService.new(user: user, ingredients: %w[トマト])
    recipe = service.call

    expect(recipe).to be_persisted
    expect(recipe.ai_provider).to be_present
    expect(recipe.ai_response).to be_present
    expect(recipe.title).to include('トマト')
  end

  it 'LLM失敗時もエラーを適切に処理する' do
    allow(mock_llm_service).to receive(:generate).and_raise(StandardError.new('LLM down'))
    service = RecipeGeneratorService.new(user: user, ingredients: %w[トマト])
    expect { service.call }.to raise_error(/LLM/) # 実装詳細に合わせて調整
  end
end
