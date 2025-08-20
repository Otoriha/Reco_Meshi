require 'rails_helper'

RSpec.describe MessageAnalyzerService do
  describe '#analyze' do
    context 'when message is a greeting' do
      it 'returns :greeting for Japanese greetings' do
        %w[こんにちは こんばんは おはよう はじめまして].each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:greeting)
        end
      end

      it 'returns :greeting for English greetings' do
        %w[hello hi hey Hello HI].each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:greeting)
        end
      end
    end

    context 'when message is a recipe command' do
      it 'returns :recipe for recipe-related messages' do
        messages = [
          'レシピ教えて',
          '何作ろうかな',
          '料理のレシピ',
          '献立を考えて',
          'recipe',
          '作り方を教えて',
          '何料理がいい？'
        ]

        messages.each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:recipe)
        end
      end
    end

    context 'when message is an ingredients command' do
      it 'returns :ingredients for ingredients-related messages' do
        messages = [
          '在庫を見せて',
          '食材リスト',
          '何がある？',
          '冷蔵庫の中身',
          'ingredients',
          '持ってる食材',
          '残ってる材料'
        ]

        messages.each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:ingredients)
        end
      end
    end

    context 'when message is a shopping command' do
      it 'returns :shopping for shopping-related messages' do
        messages = [
          '買い物リスト',
          '買うもの',
          '不足している食材',
          'shopping',
          '購入する必要があるもの',
          '足りないもの',
          'スーパーで買うもの'
        ]

        messages.each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:shopping)
        end
      end
    end

    context 'when message is a help command' do
      it 'returns :help for help-related messages' do
        messages = [
          'ヘルプ',
          '使い方',
          'help',
          '?',
          '分からない',
          'どうやって使うの？',
          '操作方法'
        ]

        messages.each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:help)
        end
      end
    end

    context 'when message is unknown' do
      it 'returns :unknown for unrecognized messages' do
        messages = [
          'ランダムなメッセージ',
          '12345',
          'asdfjkl',
          '今日は天気がいいですね'
        ]

        messages.each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:unknown)
        end
      end

      it 'returns :unknown for empty or nil messages' do
        ['', '   ', nil].each do |message|
          analyzer = described_class.new(message)
          expect(analyzer.analyze).to eq(:unknown)
        end
      end
    end

    context 'case sensitivity' do
      it 'is case insensitive for commands' do
        analyzer = described_class.new('RECIPE')
        expect(analyzer.analyze).to eq(:recipe)

        analyzer = described_class.new('INGREDIENTS')
        expect(analyzer.analyze).to eq(:ingredients)
      end
    end

    context 'mixed commands' do
      it 'returns the first matching command' do
        # レシピとヘルプの両方にマッチするが、レシピが先に定義されているため:recipeを返す
        analyzer = described_class.new('レシピの使い方')
        expect(analyzer.analyze).to eq(:recipe)
      end
    end
  end

  describe '#greeting_message?' do
    it 'correctly identifies greeting messages' do
      analyzer = described_class.new('こんにちは')
      expect(analyzer.greeting_message?).to be true

      analyzer = described_class.new('hello')
      expect(analyzer.greeting_message?).to be true

      analyzer = described_class.new('レシピ')
      expect(analyzer.greeting_message?).to be false
    end
  end
end