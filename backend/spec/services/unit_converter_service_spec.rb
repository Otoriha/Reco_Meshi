require 'rails_helper'

RSpec.describe UnitConverterService, type: :service do
  describe '.convert' do
    context '質量変換' do
      it 'g から kg に正しく変換する' do
        expect(described_class.convert(1000, from: 'g', to: 'kg')).to eq(1.0)
        expect(described_class.convert(500, from: 'g', to: 'kg')).to eq(0.5)
        expect(described_class.convert(2500, from: 'g', to: 'kg')).to eq(2.5)
      end

      it 'kg から g に正しく変換する' do
        expect(described_class.convert(1, from: 'kg', to: 'g')).to eq(1000.0)
        expect(described_class.convert(0.5, from: 'kg', to: 'g')).to eq(500.0)
        expect(described_class.convert(2.5, from: 'kg', to: 'g')).to eq(2500.0)
      end

      it '小数値を適切に丸める' do
        expect(described_class.convert(333, from: 'g', to: 'kg')).to eq(0.333)
        expect(described_class.convert(1.2345, from: 'kg', to: 'g')).to eq(1234.5)
      end
    end

    context '体積変換' do
      it 'ml から l に正しく変換する' do
        expect(described_class.convert(1000, from: 'ml', to: 'l')).to eq(1.0)
        expect(described_class.convert(500, from: 'ml', to: 'l')).to eq(0.5)
        expect(described_class.convert(1500, from: 'ml', to: 'l')).to eq(1.5)
      end

      it 'l から ml に正しく変換する' do
        expect(described_class.convert(1, from: 'l', to: 'ml')).to eq(1000.0)
        expect(described_class.convert(0.5, from: 'l', to: 'ml')).to eq(500.0)
        expect(described_class.convert(2.5, from: 'l', to: 'ml')).to eq(2500.0)
      end
    end

    context '個数系変換' do
      it '個数系単位間で1:1変換する' do
        expect(described_class.convert(5, from: '個', to: '本')).to eq(5.0)
        expect(described_class.convert(3, from: '枚', to: '個')).to eq(3.0)
        expect(described_class.convert(4, from: '尾', to: '個')).to eq(4.0)
      end
    end

    context '同一単位変換' do
      it '同じ単位では同じ値を返す' do
        expect(described_class.convert(100, from: 'g', to: 'g')).to eq(100.0)
        expect(described_class.convert(2.5, from: 'l', to: 'l')).to eq(2.5)
        expect(described_class.convert(3, from: '個', to: '個')).to eq(3.0)
      end
    end

    context '非互換単位' do
      it '異次元変換でnilを返す' do
        expect(described_class.convert(100, from: 'g', to: 'ml')).to be_nil
        expect(described_class.convert(5, from: '個', to: 'g')).to be_nil
        expect(described_class.convert(1, from: 'l', to: '個')).to be_nil
      end

      it '未サポート単位でnilを返す' do
        expect(described_class.convert(100, from: 'unsupported', to: 'g')).to be_nil
        expect(described_class.convert(100, from: 'g', to: 'unsupported')).to be_nil
      end
    end

    context '不正な入力' do
      it 'nil量でnilを返す' do
        expect(described_class.convert(nil, from: 'g', to: 'kg')).to be_nil
      end

      it '空白単位でnilを返す' do
        expect(described_class.convert(100, from: '', to: 'kg')).to be_nil
        expect(described_class.convert(100, from: 'g', to: '')).to be_nil
      end
    end
  end

  describe '.compatible?' do
    it '同次元単位で true を返す' do
      expect(described_class.compatible?(from: 'g', to: 'kg')).to be true
      expect(described_class.compatible?(from: 'ml', to: 'l')).to be true
      expect(described_class.compatible?(from: '個', to: '本')).to be true
    end

    it '異次元単位で false を返す' do
      expect(described_class.compatible?(from: 'g', to: 'ml')).to be false
      expect(described_class.compatible?(from: '個', to: 'g')).to be false
    end
  end

  describe '.dimension_of' do
    it '正しい次元を返す' do
      expect(described_class.dimension_of('g')).to eq(:mass)
      expect(described_class.dimension_of('kg')).to eq(:mass)
      expect(described_class.dimension_of('ml')).to eq(:volume)
      expect(described_class.dimension_of('l')).to eq(:volume)
      expect(described_class.dimension_of('個')).to eq(:count)
      expect(described_class.dimension_of('尾')).to eq(:count)
    end

    it '未知単位で nil を返す' do
      expect(described_class.dimension_of('unknown')).to be_nil
      expect(described_class.dimension_of('')).to be_nil
    end
  end

  describe '.supported_units' do
    it '全定義単位を含む' do
      units = described_class.supported_units
      expect(units).to include('g', 'kg', 'ml', 'l', '個', '本', '尾')
    end
  end

  describe '.base_unit_for' do
    it '正しい基本単位を返す' do
      expect(described_class.base_unit_for(:mass)).to eq('g')
      expect(described_class.base_unit_for(:volume)).to eq('ml')
      expect(described_class.base_unit_for(:count)).to eq('個')
    end
  end
end
