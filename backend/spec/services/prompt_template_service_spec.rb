require 'rails_helper'

RSpec.describe PromptTemplateService do
  describe '.recipe_generation' do
    let(:ingredients) { ['玉ねぎ', '人参', 'じゃがいも', '豚肉'] }

    it 'returns a hash with system and user prompts' do
      result = described_class.recipe_generation(ingredients: ingredients)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:system)
      expect(result).to have_key(:user)
    end

    it 'includes system prompt with constraints' do
      result = described_class.recipe_generation(ingredients: ingredients)
      system_prompt = result[:system]

      expect(system_prompt).to include('料理レシピ提案の専門家')
      expect(system_prompt).to include('日本語限定')
      expect(system_prompt).to include('1レシピのみ')
      expect(system_prompt).to include('JSON形式')
    end

    it 'includes user prompt with ingredients list' do
      result = described_class.recipe_generation(ingredients: ingredients)
      user_prompt = result[:user]

      expect(user_prompt).to include('食材: 玉ねぎ, 人参, じゃがいも, 豚肉')
      expect(user_prompt).to include('レシピを1つ提案')
    end

    it 'includes JSON format example in user prompt' do
      result = described_class.recipe_generation(ingredients: ingredients)
      user_prompt = result[:user]

      expect(user_prompt).to include('JSON')
      expect(user_prompt).to include('"title"')
      expect(user_prompt).to include('"ingredients"')
      expect(user_prompt).to include('"steps"')
    end

    context 'with empty ingredients' do
      let(:empty_ingredients) { [] }

      it 'handles empty ingredients array' do
        result = described_class.recipe_generation(ingredients: empty_ingredients)
        user_prompt = result[:user]

        expect(user_prompt).to include('食材: ')
      end
    end

    context 'with single ingredient' do
      let(:single_ingredient) { ['玉ねぎ'] }

      it 'formats single ingredient correctly' do
        result = described_class.recipe_generation(ingredients: single_ingredient)
        user_prompt = result[:user]

        expect(user_prompt).to include('食材: 玉ねぎ')
      end
    end
  end
end