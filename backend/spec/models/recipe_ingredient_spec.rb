require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user) }
  let(:ingredient) { create(:ingredient) }

  describe '関連' do
    it { is_expected.to belong_to(:recipe) }
    it { is_expected.to belong_to(:ingredient).optional }
  end

  describe 'バリデーション' do
    subject { build(:recipe_ingredient, recipe: recipe) }

    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0).allow_blank }
    it { is_expected.to validate_length_of(:unit).is_at_most(20).allow_blank }

    describe 'ingredient_idまたはingredient_nameが必要' do
      it 'ingredient_idがある場合は有効' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient, ingredient_name: nil)
        expect(ri).to be_valid
      end

      it 'ingredient_nameがある場合は有効' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: '玉ねぎ')
        expect(ri).to be_valid
      end

      it '両方ともnilの場合は無効' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: nil)
        expect(ri).not_to be_valid
        expect(ri.errors[:base]).to include('食材IDまたは食材名のいずれかを入力してください')
      end

      it '両方ともある場合は有効' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient, ingredient_name: '玉ねぎ')
        expect(ri).to be_valid
      end
    end
  end

  describe 'スコープ' do
    let!(:required_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: false) }
    let!(:optional_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: true) }
    let!(:matched_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: ingredient) }
    let!(:unmatched_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: 'unknown') }

    describe '.required' do
      it '必須食材のみ返す' do
        expect(RecipeIngredient.required).to include(required_ingredient)
        expect(RecipeIngredient.required).not_to include(optional_ingredient)
      end
    end

    describe '.optional' do
      it '任意食材のみ返す' do
        expect(RecipeIngredient.optional).to include(optional_ingredient)
        expect(RecipeIngredient.optional).not_to include(required_ingredient)
      end
    end

    describe '.with_matched_ingredient' do
      it 'ingredient_idがある食材のみ返す' do
        expect(RecipeIngredient.with_matched_ingredient).to include(matched_ingredient)
        expect(RecipeIngredient.with_matched_ingredient).not_to include(unmatched_ingredient)
      end
    end

    describe '.with_unmatched_ingredient' do
      it 'ingredient_idがnullの食材のみ返す' do
        expect(RecipeIngredient.with_unmatched_ingredient).to include(unmatched_ingredient)
        expect(RecipeIngredient.with_unmatched_ingredient).not_to include(matched_ingredient)
      end
    end
  end

  describe 'インスタンスメソッド' do
    describe '#display_name' do
      it 'ingredientがある場合はdisplay_name_with_emojiを返す' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
        expect(ri.display_name).to eq ingredient.display_name_with_emoji
      end

      it 'ingredientがなくingredient_nameがある場合はその名前を返す' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: '玉ねぎ')
        expect(ri.display_name).to eq '玉ねぎ'
      end

      it '両方ともない場合は「不明な食材」を返す' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: nil)
        expect(ri.display_name).to eq '不明な食材'
      end
    end

    describe '#formatted_amount' do
      it 'amountとunitがある場合は結合して返す' do
        ri = build(:recipe_ingredient, amount: 2.0, unit: '個')
        expect(ri.formatted_amount).to eq '2個'
      end

      it 'amountのみの場合' do
        ri = build(:recipe_ingredient, amount: 1.5, unit: nil)
        expect(ri.formatted_amount).to eq '1.5'
      end

      it 'unitのみの場合' do
        ri = build(:recipe_ingredient, amount: nil, unit: '適量')
        expect(ri.formatted_amount).to eq '適量'
      end

      it '小数点の.0を削除する' do
        ri = build(:recipe_ingredient, amount: 3.0, unit: '個')
        expect(ri.formatted_amount).to eq '3個'
      end

      it '両方ともない場合は空文字' do
        ri = build(:recipe_ingredient, amount: nil, unit: nil)
        expect(ri.formatted_amount).to eq ''
      end
    end

    describe '#full_display' do
      it '名前と分量を結合して返す' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 2.0, unit: '個')
        expected = "#{ingredient.display_name_with_emoji} 2個"
        expect(ri.full_display).to eq expected
      end

      it '分量がない場合は名前のみ' do
        ri = build(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: nil, unit: nil)
        expect(ri.full_display).to eq ingredient.display_name_with_emoji
      end
    end

    describe '#matched?' do
      it 'ingredient_idがある場合はtrue' do
        ri = build(:recipe_ingredient, ingredient: ingredient)
        expect(ri.matched?).to be true
      end

      it 'ingredient_idがない場合はfalse' do
        ri = build(:recipe_ingredient, ingredient: nil, ingredient_name: '玉ねぎ')
        expect(ri.matched?).to be false
      end
    end

    describe '#unmatched?' do
      it 'matchedの逆' do
        ri = build(:recipe_ingredient, ingredient: ingredient)
        expect(ri.unmatched?).to be false

        ri.ingredient = nil
        expect(ri.unmatched?).to be true
      end
    end

    describe '#optional_display' do
      it '任意の場合は「（お好みで）」を返す' do
        ri = build(:recipe_ingredient, is_optional: true)
        expect(ri.optional_display).to eq '（お好みで）'
      end

      it '必須の場合は空文字' do
        ri = build(:recipe_ingredient, is_optional: false)
        expect(ri.optional_display).to eq ''
      end
    end

    describe '#category' do
      it 'ingredientがある場合はそのカテゴリを返す' do
        ri = build(:recipe_ingredient, ingredient: ingredient)
        expect(ri.category).to eq ingredient.category
      end

      it 'ingredientがない場合は「unknown」を返す' do
        ri = build(:recipe_ingredient, ingredient: nil, ingredient_name: '玉ねぎ')
        expect(ri.category).to eq 'unknown'
      end
    end
  end

  describe 'クラスメソッド' do
    let!(:required_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: false) }
    let!(:optional_ingredient) { create(:recipe_ingredient, recipe: recipe, is_optional: true) }
    let!(:matched_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: ingredient) }
    let!(:unmatched_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: nil, ingredient_name: 'unknown') }

    describe '.required_count' do
      it '必須食材数を返す' do
        expect(RecipeIngredient.required_count).to eq 1
      end
    end

    describe '.optional_count' do
      it '任意食材数を返す' do
        expect(RecipeIngredient.optional_count).to eq 1
      end
    end

    describe '.matched_count' do
      it 'マッチした食材数を返す' do
        expect(RecipeIngredient.matched_count).to be >= 1
      end
    end

    describe '.unmatched_count' do
      it 'マッチしなかった食材数を返す' do
        expect(RecipeIngredient.unmatched_count).to eq 1
      end
    end
  end
end


