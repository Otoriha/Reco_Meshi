require 'rails_helper'

RSpec.describe ShoppingListBuilder, type: :service do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user, title: 'カレーライス') }
  let(:builder) { described_class.new(user, recipe) }

  describe '#initialize' do
    it 'sets user and recipe' do
      expect(builder.instance_variable_get(:@user)).to eq(user)
      expect(builder.instance_variable_get(:@recipe)).to eq(recipe)
      expect(builder.instance_variable_get(:@errors)).to eq([])
    end
  end

  describe '#build' do
    let(:onion) { create(:ingredient, name: '玉ねぎ', unit: '個', category: 'vegetables') }
    let(:pork) { create(:ingredient, name: '豚肉', unit: 'g', category: 'meat') }
    let(:curry_powder) { create(:ingredient, name: 'カレー粉', unit: 'g', category: 'seasonings') }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: onion, amount: 2, unit: '個')
      create(:recipe_ingredient, recipe: recipe, ingredient: pork, amount: 300, unit: 'g')
      create(:recipe_ingredient, recipe: recipe, ingredient: curry_powder, amount: 50, unit: 'g', is_optional: true)
    end

    context 'with valid inputs' do
      context 'when user has no ingredients' do
        it 'creates shopping list with all required ingredients' do
          result = builder.build

          expect(result).to be_a(ShoppingList)
          expect(result.user).to eq(user)
          expect(result.recipe).to eq(recipe)
          expect(result.status).to eq('pending')
          expect(result.title).to eq('カレーライスの買い物リスト')

          expect(result.shopping_list_items.count).to eq(2) # オプション材料は除く
          
          onion_item = result.shopping_list_items.find { |item| item.ingredient == onion }
          expect(onion_item.quantity).to eq(2.0)
          expect(onion_item.unit).to eq('個')

          pork_item = result.shopping_list_items.find { |item| item.ingredient == pork }
          expect(pork_item.quantity).to eq(300.0)
          expect(pork_item.unit).to eq('g')
        end
      end

      context 'when user has some ingredients' do
        before do
          create(:user_ingredient, user: user, ingredient: onion, quantity: 1, status: 'available')
          create(:user_ingredient, user: user, ingredient: pork, quantity: 150, status: 'available')
        end

        it 'creates shopping list with only missing amounts' do
          result = builder.build

          expect(result.shopping_list_items.count).to eq(2)

          onion_item = result.shopping_list_items.find { |item| item.ingredient == onion }
          expect(onion_item.quantity).to eq(1.0) # 2 - 1 = 1

          pork_item = result.shopping_list_items.find { |item| item.ingredient == pork }
          expect(pork_item.quantity).to eq(150.0) # 300 - 150 = 150
        end
      end

      context 'when user has enough ingredients' do
        before do
          create(:user_ingredient, user: user, ingredient: onion, quantity: 3, status: 'available')
          create(:user_ingredient, user: user, ingredient: pork, quantity: 500, status: 'available')
        end

        it 'creates shopping list with no items' do
          result = builder.build

          expect(result.shopping_list_items.count).to eq(0)
        end
      end

      context 'when user has expired ingredients' do
        before do
          create(:user_ingredient, user: user, ingredient: onion, quantity: 2, status: 'expired')
          create(:user_ingredient, user: user, ingredient: pork, quantity: 300, status: 'expired')
        end

        it 'ignores expired ingredients and includes all required amounts' do
          result = builder.build

          expect(result.shopping_list_items.count).to eq(2)

          onion_item = result.shopping_list_items.find { |item| item.ingredient == onion }
          expect(onion_item.quantity).to eq(2.0)

          pork_item = result.shopping_list_items.find { |item| item.ingredient == pork }
          expect(pork_item.quantity).to eq(300.0)
        end
      end
    end

    context 'with invalid inputs' do
      context 'when user is nil' do
        let(:builder) { described_class.new(nil, recipe) }

        it 'raises error with appropriate message' do
          expect { builder.build }.to raise_error(StandardError, /ユーザーが指定されていません/)
        end
      end

      context 'when recipe is nil' do
        let(:builder) { described_class.new(user, nil) }

        it 'raises error with appropriate message' do
          expect { builder.build }.to raise_error(StandardError, /レシピが指定されていません/)
        end
      end

      context 'when recipe has no ingredients' do
        let(:empty_recipe) { create(:recipe, user: user, title: '空のレシピ') }
        let(:builder) { described_class.new(user, empty_recipe) }

        it 'raises error with appropriate message' do
          expect { builder.build }.to raise_error(StandardError, /レシピに材料が含まれていません/)
        end
      end
    end

    describe 'ingredient consolidation' do
      let(:tomato) { create(:ingredient, name: 'トマト', unit: 'g', category: 'vegetables') }

      before do
        # 同じ食材を異なる量で2回追加
        create(:recipe_ingredient, recipe: recipe, ingredient: tomato, amount: 200, unit: 'g')
        create(:recipe_ingredient, recipe: recipe, ingredient: tomato, amount: 100, unit: 'g')
      end

      it 'consolidates same ingredients with same unit' do
        result = builder.build

        tomato_items = result.shopping_list_items.select { |item| item.ingredient == tomato }
        expect(tomato_items.count).to eq(1)
        expect(tomato_items.first.quantity).to eq(300.0) # 200 + 100
      end
    end

    describe 'unit normalization' do
      let(:flour) { create(:ingredient, name: '小麦粉', unit: 'g', category: 'others') }

      context 'when recipe unit is in allowed units' do
        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: flour, amount: 500, unit: 'g')
        end

        it 'uses recipe unit' do
          result = builder.build
          
          flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
          expect(flour_item.unit).to eq('g')
        end
      end

      context 'when recipe unit is not in allowed units' do
        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: flour, amount: 1, unit: 'cup')
        end

        it 'falls back to ingredient unit' do
          result = builder.build
          
          flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
          expect(flour_item.unit).to eq('g')
        end
      end
    end

    describe 'transaction rollback' do
      before do
        create(:recipe_ingredient, recipe: recipe, ingredient: onion, amount: 2, unit: '個')
        
        # モックで保存を失敗させる
        allow_any_instance_of(ShoppingListItem).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new)
      end

      it 'rolls back transaction on failure' do
        expect { builder.build }.to raise_error(StandardError, /買い物リストの作成に失敗しました/)
        
        # ロールバックにより、ShoppingListが作成されないことを確認
        expect(user.shopping_lists.count).to eq(0)
      end
    end
  end

  describe 'private methods' do
    describe '#normalize_quantity' do
      it 'returns 1.0 for zero or negative amounts' do
        result = builder.send(:normalize_quantity, 0)
        expect(result).to eq(1.0)

        result = builder.send(:normalize_quantity, -5)
        expect(result).to eq(1.0)
      end

      it 'returns integer as float for whole numbers' do
        result = builder.send(:normalize_quantity, 3)
        expect(result).to eq(3.0)
      end

      it 'rounds decimals to 2 places' do
        result = builder.send(:normalize_quantity, 2.555)
        expect(result).to eq(2.56)
      end
    end

    describe '#normalize_unit' do
      it 'returns ingredient unit when recipe unit is blank' do
        result = builder.send(:normalize_unit, '', 'g')
        expect(result).to eq('g')
      end

      it 'returns recipe unit when it is allowed' do
        result = builder.send(:normalize_unit, 'kg', 'g')
        expect(result).to eq('kg')
      end

      it 'returns ingredient unit when recipe unit is not allowed' do
        result = builder.send(:normalize_unit, 'invalid_unit', 'g')
        expect(result).to eq('g')
      end
    end
  end
end