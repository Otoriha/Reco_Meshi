require 'rails_helper'

RSpec.describe Recipe, type: :model do
  let(:user) { create(:user) }
  
  describe 'バリデーション' do
    subject { build(:recipe, user: user) }
    
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:cooking_time) }
    it { is_expected.to validate_presence_of(:steps) }
    it { is_expected.to validate_presence_of(:ai_provider) }
    
    it { is_expected.to validate_numericality_of(:cooking_time).is_greater_than(0).is_less_than_or_equal_to(480) }
    # shoulda-matchers のnumericalityは allow_blank を未サポートのため allow_nil を使用
    it { is_expected.to validate_numericality_of(:servings).is_greater_than(0).is_less_than_or_equal_to(20).allow_nil }
    
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_inclusion_of(:ai_provider).in_array(%w[openai gemini]) }
    # enum(文字列)に対する shoulda の allow_blank は未サポートのため allow_nil を使用
    # enum(文字列)はshouldaのサポートが限定的なため、手動で検証
    it 'difficulty は easy/medium/hard のみ許可される' do
      expect(Recipe.difficulties.keys).to match_array(%w[easy medium hard])
      expect(build(:recipe, user: user, difficulty: 'easy')).to be_valid
      expect { build(:recipe, user: user, difficulty: 'invalid') }.to raise_error(ArgumentError)
    end
  end

  describe 'Enum' do
    it 'difficulty enumが正しく動作する' do
      recipe = build(:recipe, user: user, difficulty: 'easy')
      expect(recipe.difficulty_easy?).to be true
      expect(recipe.difficulty).to eq 'easy'
    end
  end

  describe '関連' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:recipe_ingredients).dependent(:destroy) }
    it { is_expected.to have_many(:ingredients).through(:recipe_ingredients) }
  end

  describe 'スコープ' do
    let!(:older_recipe) { create(:recipe, user: user, created_at: 2.days.ago) }
    let!(:newer_recipe) { create(:recipe, user: user, created_at: 1.day.ago) }
    
    describe '.recent' do
      it '作成日時の降順で並ぶ' do
        expect(Recipe.recent.first).to eq(newer_recipe)
        expect(Recipe.recent.last).to eq(older_recipe)
      end
    end

    describe '.by_user' do
      it '指定ユーザーのレシピのみ返す' do
        other_user = create(:user)
        other_recipe = create(:recipe, user: other_user)
        
        expect(Recipe.by_user(user.id)).to contain_exactly(older_recipe, newer_recipe)
        expect(Recipe.by_user(user.id)).not_to include(other_recipe)
      end
    end

    describe '.by_difficulty' do
      let!(:easy_recipe) { create(:recipe, user: user, difficulty: 'easy') }
      let!(:hard_recipe) { create(:recipe, user: user, difficulty: 'hard') }

      it '指定した難易度のレシピのみ返す' do
        expect(Recipe.by_difficulty('easy')).to include(easy_recipe)
        expect(Recipe.by_difficulty('easy')).not_to include(hard_recipe)
      end
    end

    describe '.short_cooking_time' do
      let!(:quick_recipe) { create(:recipe, user: user, cooking_time: 15) }
      let!(:long_recipe) { create(:recipe, user: user, cooking_time: 60) }

      it '指定時間以下のレシピのみ返す' do
        expect(Recipe.short_cooking_time(30)).to include(quick_recipe)
        expect(Recipe.short_cooking_time(30)).not_to include(long_recipe)
      end
    end
  end

  describe 'インスタンスメソッド' do
    let(:recipe) { create(:recipe, user: user, cooking_time: 90, difficulty: 'medium', steps: steps_data) }
    let(:steps_data) do
      [
        { 'order' => 1, 'text' => '野菜を切る' },
        { 'order' => 2, 'text' => '炒める' }
      ]
    end

    describe '#formatted_cooking_time' do
      it '分のみの場合' do
        recipe.cooking_time = 30
        expect(recipe.formatted_cooking_time).to eq '30分'
      end

      it '時間と分の場合' do
        recipe.cooking_time = 90
        expect(recipe.formatted_cooking_time).to eq '1時間30分'
      end

      it '時間のみの場合' do
        recipe.cooking_time = 120
        expect(recipe.formatted_cooking_time).to eq '2時間'
      end
    end

    describe '#difficulty_display' do
      it 'easyの場合' do
        recipe.difficulty = 'easy'
        expect(recipe.difficulty_display).to eq '簡単 ⭐'
      end

      it 'mediumの場合' do
        recipe.difficulty = 'medium'
        expect(recipe.difficulty_display).to eq '普通 ⭐⭐'
      end

      it 'hardの場合' do
        recipe.difficulty = 'hard'
        expect(recipe.difficulty_display).to eq '難しい ⭐⭐⭐'
      end

      it 'nilの場合' do
        recipe.difficulty = nil
        expect(recipe.difficulty_display).to eq '指定なし'
      end
    end

    describe '#steps_as_array' do
      it '構造化されたstepsから手順文字列を抽出' do
        expect(recipe.steps_as_array).to eq ['野菜を切る', '炒める']
      end

      it 'シンプルな文字列配列の場合' do
        recipe.steps = ['手順1', '手順2']
        expect(recipe.steps_as_array).to eq ['手順1', '手順2']
      end

      it '空の場合' do
        recipe.steps = []
        expect(recipe.steps_as_array).to eq []
      end
    end

    describe 'recipe_ingredients関連のメソッド' do
      let!(:required_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: false) }
      let!(:optional_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: true) }

      describe '#total_ingredients_count' do
        it '全食材数を返す' do
          expect(recipe.total_ingredients_count).to eq 2
        end
      end

      describe '#required_ingredients_count' do
        it '必須食材数を返す' do
          expect(recipe.required_ingredients_count).to eq 1
        end
      end

      describe '#optional_ingredients_count' do
        it '任意食材数を返す' do
          expect(recipe.optional_ingredients_count).to eq 1
        end
      end
    end
  end
end
