require 'rails_helper'

RSpec.describe 'RecipeConverterService' do
  before do
    skip 'RecipeConverterService 未実装のためスキップ' unless defined?(RecipeConverterService)
  end

  let(:user) { create(:user) }
  let(:matcher) { instance_double(IngredientMatcher) }

  let(:ai_json) do
    {
      'title' => 'トマト炒め',
      'time' => '約15分',
      'difficulty' => 'easy',
      'ingredients' => [
        { 'name' => 'トマト', 'amount' => '2個' },
        { 'name' => '塩', 'amount' => '少々' }
      ],
      'steps' => [
        'トマトを切る',
        '炒めて塩で味を整える'
      ]
    }
  end

  it 'AI JSONをRecipe/RecipeIngredientに変換し保存する（食材マッチ成功）' do
    allow(IngredientMatcher).to receive(:new).and_return(matcher)
    tomato = create(:ingredient, name: 'トマト', category: 'vegetables', unit: '個')
    allow(matcher).to receive(:find_ingredients_batch).and_return({
      'トマト' => { ingredient: tomato, confidence: 1.0 },
      '塩' => nil
    })

    service = RecipeConverterService.new(user: user, ai_json: ai_json)
    result = service.convert_and_save!

    expect(result).to be_a(Recipe)
    expect(result.title).to eq('トマト炒め')
    expect(result.cooking_time).to be >= 0
    expect(result.steps).to be_an(Array)
    expect(result.recipe_ingredients.count).to eq(2)
    expect(result.recipe_ingredients.map(&:ingredient_id)).to include(tomato.id)
    expect(result.recipe_ingredients.map(&:ingredient_name)).to include('塩')
  end

  it '必須項目が欠落している場合は例外/エラーを返す' do
    invalid_json = ai_json.merge('title' => nil)
    service = RecipeConverterService.new(user: user, ai_json: invalid_json)
    expect { service.convert_and_save! }.to raise_error(/title/i)
  end
end


