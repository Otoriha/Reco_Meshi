require 'rails_helper'

RSpec.describe ShoppingListGeneratorService, type: :service do
  let(:user) { create(:user) }
  let(:recipe1) { create(:recipe, user: user, title: 'カレーライス') }
  let(:recipe2) { create(:recipe, user: user, title: 'ハンバーグ') }
  let(:generator) { described_class.new(user, [recipe1, recipe2]) }

  describe '#initialize' do
    it 'sets user and recipes' do
      expect(generator.instance_variable_get(:@user)).to eq(user)
      expect(generator.instance_variable_get(:@recipes)).to eq([recipe1, recipe2])
      expect(generator.instance_variable_get(:@errors)).to eq([])
    end

    it 'converts single recipe to array' do
      single_generator = described_class.new(user, recipe1)
      expect(single_generator.instance_variable_get(:@recipes)).to eq([recipe1])
    end
  end

  describe '#generate' do
    let(:onion) { create(:ingredient, name: '玉ねぎ', unit: '個', category: 'vegetables') }
    let(:pork) { create(:ingredient, name: '豚肉', unit: 'g', category: 'meat') }
    let(:flour) { create(:ingredient, name: '小麦粉', unit: 'g', category: 'others') }

    before do
      # recipe1 の材料
      create(:recipe_ingredient, recipe: recipe1, ingredient: onion, amount: 2, unit: '個')
      create(:recipe_ingredient, recipe: recipe1, ingredient: pork, amount: 200, unit: 'g')

      # recipe2 の材料
      create(:recipe_ingredient, recipe: recipe2, ingredient: onion, amount: 1, unit: '個')
      create(:recipe_ingredient, recipe: recipe2, ingredient: pork, amount: 300, unit: 'g')
      create(:recipe_ingredient, recipe: recipe2, ingredient: flour, amount: 100, unit: 'g')
    end

    context 'with valid inputs and no existing inventory' do
      it 'creates shopping list with aggregated ingredients' do
        result = generator.generate

        expect(result).to be_a(ShoppingList)
        expect(result.user).to eq(user)
        expect(result.recipe).to be_nil # 複数レシピなのでrecipe_idはnil
        expect(result.status).to eq('pending')
        expect(result.title).to eq('2レシピの買い物リスト')
        expect(result.note).to eq('対象レシピ: カレーライス、ハンバーグ')

        expect(result.shopping_list_items.count).to eq(3)

        # 玉ねぎ: 2個 + 1個 = 3個
        onion_item = result.shopping_list_items.find { |item| item.ingredient == onion }
        expect(onion_item.quantity).to eq(3.0)
        expect(onion_item.unit).to eq('個')

        # 豚肉: 200g + 300g = 500g
        pork_item = result.shopping_list_items.find { |item| item.ingredient == pork }
        expect(pork_item.quantity).to eq(500.0)
        expect(pork_item.unit).to eq('g')

        # 小麦粉: 100g
        flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
        expect(flour_item.quantity).to eq(100.0)
        expect(flour_item.unit).to eq('g')
      end
    end

    context 'with existing inventory' do
      before do
        create(:user_ingredient, user: user, ingredient: onion, quantity: 2, status: 'available')
        create(:user_ingredient, user: user, ingredient: pork, quantity: 100, status: 'available')
      end

      it 'calculates shortage after aggregation' do
        result = generator.generate

        # 玉ねぎ: 必要3個 - 在庫2個 = 不足1個
        onion_item = result.shopping_list_items.find { |item| item.ingredient == onion }
        expect(onion_item.quantity).to eq(1.0)

        # 豚肉: 必要500g - 在庫100g = 不足400g
        pork_item = result.shopping_list_items.find { |item| item.ingredient == pork }
        expect(pork_item.quantity).to eq(400.0)

        # 小麦粉: 在庫なしなので不足100g
        flour_item = result.shopping_list_items.find { |item| item.ingredient == flour }
        expect(flour_item.quantity).to eq(100.0)
      end
    end

    context 'with sufficient inventory' do
      before do
        create(:user_ingredient, user: user, ingredient: onion, quantity: 5, status: 'available')
        create(:user_ingredient, user: user, ingredient: pork, quantity: 600, status: 'available')
        create(:user_ingredient, user: user, ingredient: flour, quantity: 200, status: 'available')
      end

      it 'creates shopping list with only insufficient items' do
        result = generator.generate

        expect(result.shopping_list_items.count).to eq(0)
      end
    end

    context 'with unit conversion' do
      let(:sugar) { create(:ingredient, name: '砂糖', unit: 'g', category: 'others') }
      let(:milk) { create(:ingredient, name: '牛乳', unit: 'ml', category: 'dairy') }

      before do
        # 異なる単位で同じ食材を使用
        create(:recipe_ingredient, recipe: recipe1, ingredient: sugar, amount: 0.5, unit: 'kg')
        create(:recipe_ingredient, recipe: recipe2, ingredient: sugar, amount: 200, unit: 'g')
        create(:recipe_ingredient, recipe: recipe1, ingredient: milk, amount: 1, unit: 'l')

        create(:user_ingredient, user: user, ingredient: sugar, quantity: 100, status: 'available')
        create(:user_ingredient, user: user, ingredient: milk, quantity: 300, status: 'available')
      end

      it 'aggregates with unit conversion and calculates shortage' do
        result = generator.generate

        # 砂糖: 0.5kg(500g) + 200g = 700g、在庫100g、不足600g
        sugar_item = result.shopping_list_items.find { |item| item.ingredient == sugar }
        expect(sugar_item.quantity).to eq(600.0)
        expect(sugar_item.unit).to eq('g')

        # 牛乳: 1l(1000ml)、在庫300ml、不足700ml
        milk_item = result.shopping_list_items.find { |item| item.ingredient == milk }
        expect(milk_item.quantity).to eq(700.0)
        expect(milk_item.unit).to eq('ml')
      end
    end

    context 'with incompatible units' do
      let(:fish) { create(:ingredient, name: 'さば', unit: '尾', category: 'fish') }

      before do
        create(:recipe_ingredient, recipe: recipe1, ingredient: fish, amount: 200, unit: 'g')
        create(:user_ingredient, user: user, ingredient: fish, quantity: 1, status: 'available')
      end

      it 'ignores inventory for incompatible units' do
        allow(Rails.logger).to receive(:warn)

        result = generator.generate

        # 在庫を無視してレシピ量そのまま、ただし最終単位は食材マスター単位
        fish_item = result.shopping_list_items.find { |item| item.ingredient == fish }
        expect(fish_item.quantity).to eq(1.0) # 変換不可なので概算値として1.0
        expect(fish_item.unit).to eq('尾') # 食材マスター単位

        expect(Rails.logger).to have_received(:warn)
      end
    end

    context 'with mixed convertible and inconvertible units for same ingredient' do
      let(:flour) { create(:ingredient, name: '小麦粉', unit: 'g', category: 'others') }

      before do
        # 同一食材で変換可能な単位と変換不可な単位が混在
        create(:recipe_ingredient, recipe: recipe1, ingredient: flour, amount: 1, unit: 'kg') # 変換可能 → 1000g
        create(:recipe_ingredient, recipe: recipe2, ingredient: flour, amount: 2, unit: 'cup') # 変換不可

        create(:user_ingredient, user: user, ingredient: flour, quantity: 500, status: 'available')
      end

      it 'consolidates all requirements into single item with ingredient unit' do
        allow(Rails.logger).to receive(:warn)

        result = generator.generate

        flour_items = result.shopping_list_items.select { |item| item.ingredient == flour }
        expect(flour_items.count).to eq(1) # 必ず1つの行に統一

        flour_item = flour_items.first
        expect(flour_item.unit).to eq('g') # 最終単位は食材マスター単位
        
        # 1kg(1000g) + 2cup(概算1g) - 在庫500g = 501g
        expect(flour_item.quantity).to eq(501.0)

        # 変換不可警告とUn変換不可警告の両方が出ることを確認
        expect(Rails.logger).to have_received(:warn).at_least(:once)
      end
    end

    context 'with single recipe' do
      let(:single_generator) { described_class.new(user, recipe1) }

      before do
        create(:recipe_ingredient, recipe: recipe1, ingredient: onion, amount: 2, unit: '個')
      end

      it 'creates shopping list with single recipe title' do
        result = single_generator.generate

        expect(result.title).to eq('カレーライスの買い物リスト')
        expect(result.note).to eq('対象レシピ: カレーライス')
      end
    end

    context 'with category grouping' do
      let(:tomato) { create(:ingredient, name: 'トマト', unit: '個', category: 'vegetables') }
      let(:salt) { create(:ingredient, name: '塩', unit: 'g', category: 'seasonings') }

      before do
        create(:recipe_ingredient, recipe: recipe1, ingredient: onion, amount: 1, unit: '個')
        create(:recipe_ingredient, recipe: recipe1, ingredient: tomato, amount: 2, unit: '個')
        create(:recipe_ingredient, recipe: recipe1, ingredient: pork, amount: 200, unit: 'g')
        create(:recipe_ingredient, recipe: recipe1, ingredient: salt, amount: 5, unit: 'g')
      end

      it 'groups items by category in correct order' do
        result = generator.generate

        items = result.shopping_list_items.includes(:ingredient).to_a
        categories = items.map { |item| item.ingredient.category }

        # vegetables -> meat -> seasonings の順序
        expect(categories).to eq(['vegetables', 'vegetables', 'meat', 'seasonings'])
      end
    end

    context 'with invalid inputs' do
      context 'when user is nil' do
        let(:generator) { described_class.new(nil, [recipe1]) }

        it 'raises error with appropriate message' do
          expect { generator.generate }.to raise_error(StandardError, /ユーザーが指定されていません/)
        end
      end

      context 'when recipes is empty' do
        let(:generator) { described_class.new(user, []) }

        it 'raises error with appropriate message' do
          expect { generator.generate }.to raise_error(StandardError, /レシピが指定されていません/)
        end
      end

      context 'when recipe has no ingredients' do
        let(:empty_recipe) { create(:recipe, user: user, title: '空のレシピ') }
        let(:generator) { described_class.new(user, [empty_recipe]) }

        it 'raises error with appropriate message' do
          expect { generator.generate }.to raise_error(StandardError, /レシピに材料が含まれていません/)
        end
      end

      context 'when recipe belongs to different user' do
        let(:other_user) { create(:user) }
        let(:other_recipe) { create(:recipe, user: other_user, title: '他人のレシピ') }
        let(:generator) { described_class.new(user, [other_recipe]) }

        before do
          create(:recipe_ingredient, recipe: other_recipe, ingredient: onion, amount: 1, unit: '個')
        end

        it 'raises error with appropriate message' do
          expect { generator.generate }.to raise_error(StandardError, /アクセス権限がありません/)
        end
      end
    end

    context 'with optional ingredients' do
      before do
        create(:recipe_ingredient, recipe: recipe1, ingredient: onion, amount: 2, unit: '個')
        create(:recipe_ingredient, recipe: recipe1, ingredient: pork, amount: 200, unit: 'g', is_optional: true)
      end

      it 'ignores optional ingredients' do
        result = generator.generate

        expect(result.shopping_list_items.count).to eq(1)

        onion_item = result.shopping_list_items.first
        expect(onion_item.ingredient).to eq(onion)
      end
    end
  end
end