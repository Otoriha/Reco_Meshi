require 'rails_helper'

RSpec.describe RecipeConverter do
  let(:user) { create(:user) }
  let(:converter) { RecipeConverter.new }

  describe '#normalize_difficulty' do
    context '文字列での指定' do
      it 'easy系の文字列を正しく変換する' do
        expect(converter.send(:normalize_difficulty, 'easy')).to eq('easy')
        expect(converter.send(:normalize_difficulty, '簡単')).to eq('easy')
        expect(converter.send(:normalize_difficulty, 'かんたん')).to eq('easy')
      end

      it 'medium系の文字列を正しく変換する' do
        expect(converter.send(:normalize_difficulty, 'medium')).to eq('medium')
        expect(converter.send(:normalize_difficulty, '普通')).to eq('medium')
        expect(converter.send(:normalize_difficulty, 'ふつう')).to eq('medium')
      end

      it 'hard系の文字列を正しく変換する' do
        expect(converter.send(:normalize_difficulty, 'hard')).to eq('hard')
        expect(converter.send(:normalize_difficulty, '難しい')).to eq('hard')
        expect(converter.send(:normalize_difficulty, 'むずかしい')).to eq('hard')
      end
    end

    context '星マークでの指定' do
      it '★1個をeasyに変換する' do
        expect(converter.send(:normalize_difficulty, '★')).to eq('easy')
        expect(converter.send(:normalize_difficulty, '⭐')).to eq('easy')
        expect(converter.send(:normalize_difficulty, '★☆☆')).to eq('easy')
      end

      it '★2個をmediumに変換する' do
        expect(converter.send(:normalize_difficulty, '★★')).to eq('medium')
        expect(converter.send(:normalize_difficulty, '⭐⭐')).to eq('medium')
        expect(converter.send(:normalize_difficulty, '★★☆')).to eq('medium')
      end

      it '★3個をhardに変換する' do
        expect(converter.send(:normalize_difficulty, '★★★')).to eq('hard')
        expect(converter.send(:normalize_difficulty, '⭐⭐⭐')).to eq('hard')
      end
    end

    context '空や不正な値' do
      it 'nilや空文字列でnilを返す' do
        expect(converter.send(:normalize_difficulty, nil)).to be_nil
        expect(converter.send(:normalize_difficulty, '')).to be_nil
        expect(converter.send(:normalize_difficulty, '   ')).to be_nil
      end

      it '不明な値でnilを返す（警告付き）' do
        expect(converter.send(:normalize_difficulty, 'unknown')).to be_nil
      end
    end
  end
end
