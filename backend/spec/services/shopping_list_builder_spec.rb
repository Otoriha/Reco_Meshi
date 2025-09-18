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

    describe 'unit conversion' do
      let(:flour) { create(:ingredient, name: '小麦粉', unit: 'g', category: 'others') }
      let(:milk) { create(:ingredient, name: '牛乳', unit: 'ml', category: 'dairy') }

      context 'when recipe unit is compatible with ingredient unit' do
        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: flour, amount: 2, unit: 'kg')
          create(:recipe_ingredient, recipe: recipe, ingredient: milk, amount: 1, unit: 'l')
          create(:user_ingredient, user: user, ingredient: flour, quantity: 500, status: 'available')
          create(:user_ingredient, user: user, ingredient: milk, quantity: 200, status: 'available')
        end

        it 'converts recipe units to ingredient units and calculates shortage' do
          result = builder.build

          flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
          expect(flour_item.quantity).to eq(1500.0) # 2kg - 500g = 1500g
          expect(flour_item.unit).to eq('g')

          milk_item = result.shopping_list_items.find { |item| item.ingredient == milk }
          expect(milk_item.quantity).to eq(800.0) # 1l - 200ml = 800ml
          expect(milk_item.unit).to eq('ml')
        end
      end

      context 'when recipe unit is incompatible with ingredient unit' do
        let(:fish) { create(:ingredient, name: 'さば', unit: '尾', category: 'fish') }

        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: fish, amount: 200, unit: 'g')
          create(:user_ingredient, user: user, ingredient: fish, quantity: 1, status: 'available')
        end

        it 'ignores inventory and uses recipe amount as is' do
          allow(Rails.logger).to receive(:warn)

          result = builder.build

          fish_item = result.shopping_list_items.find { |item| item.ingredient == fish }
          expect(fish_item.quantity).to eq(200.0) # 在庫無視でレシピ量そのまま
          expect(fish_item.unit).to eq('g')

          expect(Rails.logger).to have_received(:warn)
        end
      end

      context 'when recipe unit is unsupported and incompatible with ingredient unit' do
        let(:flour) { create(:ingredient, name: '小麦粉', unit: 'g', category: 'others') }

        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: flour, amount: 2, unit: 'cup') # unsupported unit
          create(:user_ingredient, user: user, ingredient: flour, quantity: 100, status: 'available')
        end

        it 'falls back to ingredient unit when recipe unit is not allowed' do
          allow(Rails.logger).to receive(:warn)

          result = builder.build

          flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
          expect(flour_item.quantity).to eq(2.0) # 変換不可で在庫無視でレシピ量そのまま
          expect(flour_item.unit).to eq('g') # 未許可単位なので食材単位にフォールバック

          expect(Rails.logger).to have_received(:warn)
        end
      end

      context 'when user has sufficient inventory after conversion' do
        before do
          create(:recipe_ingredient, recipe: recipe, ingredient: flour, amount: 1, unit: 'kg')
          create(:user_ingredient, user: user, ingredient: flour, quantity: 1200, status: 'available')
        end

        it 'does not add item to shopping list' do
          result = builder.build

          flour_items = result.shopping_list_items.select { |item| item.ingredient == flour }
          expect(flour_items).to be_empty
        end
      end
    end

    describe 'ingredient consolidation after unit conversion' do
      let(:sugar) { create(:ingredient, name: '砂糖', unit: 'g', category: 'others') }

      before do
        # 同じ食材を異なる単位で2回追加（変換後は同じ単位になる）
        create(:recipe_ingredient, recipe: recipe, ingredient: sugar, amount: 0.5, unit: 'kg')
        create(:recipe_ingredient, recipe: recipe, ingredient: sugar, amount: 200, unit: 'g')
      end

      it 'consolidates ingredients by ingredient_id only after unit conversion' do
        result = builder.build

        sugar_items = result.shopping_list_items.select { |item| item.ingredient == sugar }
        expect(sugar_items.count).to eq(1)
        expect(sugar_items.first.quantity).to eq(700.0) # 500g + 200g
        expect(sugar_items.first.unit).to eq('g')
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
