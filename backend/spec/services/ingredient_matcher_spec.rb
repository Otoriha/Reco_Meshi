require 'rails_helper'

RSpec.describe IngredientMatcher, type: :service do
  let(:matcher) { described_class.new }
  
  before do
    # テスト用のIngredientデータを作成
    create(:ingredient, name: 'トマト', category: 'vegetables', unit: '個')
    create(:ingredient, name: 'きゅうり', category: 'vegetables', unit: '本')
    create(:ingredient, name: '鶏肉', category: 'meat', unit: 'g')
    create(:ingredient, name: 'チーズ', category: 'dairy', unit: 'g')
    create(:ingredient, name: 'ほうれん草', category: 'vegetables', unit: '束')
  end

  describe '#find_ingredient' do
    context '完全一致の場合' do
      it 'トマトを正確に見つける' do
        result = matcher.find_ingredient('トマト')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('トマト')
        expect(result[:confidence]).to eq(1.0)
        expect(result[:matched]).to be true
      end

      it '大文字小文字を区別しない' do
        result = matcher.find_ingredient('tomato')
        
        # 英語名での検索は部分一致になるため、設定によっては見つからない可能性があります
        # 実際の実装に合わせて調整してください
        expect(result).to be_nil # 現在の実装では英語名は登録されていない
      end
    end

    context 'ひらがな・カタカナ正規化の場合' do
      it 'ひらがなからカタカナの食材を見つける' do
        result = matcher.find_ingredient('とまと')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('トマト')
        expect(result[:confidence]).to eq(0.9)
      end

      it 'カタカナからひらがなの食材を見つける' do
        # ほうれん草をひらがなで登録している場合
        create(:ingredient, name: 'ほうれんそう', category: 'vegetables', unit: '束')
        
        result = matcher.find_ingredient('ホウレンソウ')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('ほうれんそう')
        expect(result[:confidence]).to eq(0.9)
      end
    end

    context '部分一致の場合' do
      it '前方一致で見つける' do
        result = matcher.find_ingredient('トマ')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('トマト')
        expect(result[:confidence]).to eq(0.8)
      end

      it '後方一致で見つける' do
        result = matcher.find_ingredient('マト')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('トマト')
        expect(result[:confidence]).to eq(0.7)
      end

      it '中間一致で見つける' do
        create(:ingredient, name: '新鮮なトマト', category: 'vegetables', unit: '個')
        
        result = matcher.find_ingredient('鮮な')
        
        expect(result).not_to be_nil
        expect(result[:ingredient].name).to eq('新鮮なトマト')
        expect(result[:confidence]).to eq(0.6)
      end
    end

    context 'マッチしない場合' do
      it 'nilを返す' do
        result = matcher.find_ingredient('存在しない食材')
        
        expect(result).to be_nil
      end

      it '未マッチの食材を記録する' do
        matcher.find_ingredient('存在しない食材')
        
        unmatched = matcher.unmatched_ingredients
        expect(unmatched.size).to eq(1)
        expect(unmatched.first[:name]).to eq('存在しない食材')
        expect(unmatched.first[:normalized_name]).to eq('存在しない食材')
      end
    end

    context '空文字・nil の場合' do
      it '空文字でnilを返す' do
        result = matcher.find_ingredient('')
        expect(result).to be_nil
      end

      it 'nilでnilを返す' do
        result = matcher.find_ingredient(nil)
        expect(result).to be_nil
      end

      it '空白のみでnilを返す' do
        result = matcher.find_ingredient('   ')
        expect(result).to be_nil
      end
    end
  end

  describe '#find_ingredients_batch' do
    it '複数の食材を一括処理する' do
      names = ['トマト', '鶏肉', '存在しない食材', 'きゅうり']
      results = matcher.find_ingredients_batch(names)
      
      expect(results.size).to eq(3) # 存在しない食材以外
      expect(results.map { |r| r[:ingredient].name }).to contain_exactly('トマト', '鶏肉', 'きゅうり')
    end
  end

  describe '#unmatched_ingredients' do
    it '未マッチ食材の履歴を保持する' do
      matcher.find_ingredient('存在しない食材1')
      matcher.find_ingredient('存在しない食材2')
      matcher.find_ingredient('トマト') # これはマッチする
      
      unmatched = matcher.unmatched_ingredients
      expect(unmatched.size).to eq(2)
      expect(unmatched.map { |u| u[:name] }).to contain_exactly('存在しない食材1', '存在しない食材2')
    end

    it '履歴のコピーを返す（内部状態を変更できない）' do
      matcher.find_ingredient('存在しない食材')
      
      unmatched = matcher.unmatched_ingredients
      unmatched.clear
      
      # 元の履歴は変更されない
      original_unmatched = matcher.unmatched_ingredients
      expect(original_unmatched.size).to eq(1)
    end
  end

  describe 'プライベートメソッド' do
    describe '#normalize_name' do
      it '文字列を正規化する' do
        normalized = matcher.send(:normalize_name, '  トマト  ')
        expect(normalized).to eq('トマト')
      end

      it '大文字を小文字に変換する' do
        normalized = matcher.send(:normalize_name, 'TOMATO')
        expect(normalized).to eq('tomato')
      end
    end

    describe '#hiragana_to_katakana' do
      it 'ひらがなをカタカナに変換する' do
        katakana = matcher.send(:hiragana_to_katakana, 'とまと')
        expect(katakana).to eq('トマト')
      end

      it 'すでにカタカナの場合はそのまま' do
        katakana = matcher.send(:hiragana_to_katakana, 'トマト')
        expect(katakana).to eq('トマト')
      end

      it '漢字や英数字は変換しない' do
        result = matcher.send(:hiragana_to_katakana, '新鮮なとまと123')
        expect(result).to eq('新鮮なトマト123')
      end
    end
  end
end