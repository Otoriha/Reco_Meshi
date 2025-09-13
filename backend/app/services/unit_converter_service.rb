class UnitConverterService
  # 単位変換表（基本単位に対する倍数）
  CONVERSIONS = {
    mass: {
      'g' => 1.0,
      'kg' => 1000.0
    },
    volume: {
      'ml' => 1.0,
      'l' => 1000.0
    },
    # 個数系は相互変換しない（係数1.0で統一）
    count: %w[個 本 束 パック 袋 枚 缶 瓶 箱 玉 尾]
  }.freeze

  class << self
    # 単位変換を実行する
    # @param amount [Numeric] 変換する数量
    # @param from [String] 変換元の単位
    # @param to [String] 変換先の単位
    # @return [Float, nil] 変換後の数量、変換不可能な場合はnil
    def convert(amount, from:, to:)
      return nil if amount.nil? || from.blank? || to.blank?
      return amount.to_f if from == to

      from_dimension = dimension_of(from)
      to_dimension = dimension_of(to)
      
      # 異なるディメンション間は変換不可
      return nil unless from_dimension && from_dimension == to_dimension
      
      case from_dimension
      when :mass, :volume
        conversion_table = CONVERSIONS[from_dimension]
        from_ratio = conversion_table[from]
        to_ratio = conversion_table[to]
        
        return nil if from_ratio.nil? || to_ratio.nil?
        
        # 基本単位での値を計算してから目標単位に変換
        base_amount = amount.to_f * from_ratio
        (base_amount / to_ratio).round(3)
      when :count
        # 個数系は1:1で変換（実質変換なし）
        amount.to_f
      else
        nil
      end
    end

    # 単位の互換性をチェックする
    # @param from [String] 変換元の単位
    # @param to [String] 変換先の単位
    # @return [Boolean] 変換可能な場合true
    def compatible?(from:, to:)
      return true if from == to
      return false if from.blank? || to.blank?
      
      from_dimension = dimension_of(from)
      to_dimension = dimension_of(to)
      
      from_dimension && from_dimension == to_dimension
    end

    # 単位のディメンション（次元）を判定する
    # @param unit [String] 単位
    # @return [Symbol, nil] :mass, :volume, :count, nil（未知の単位）
    def dimension_of(unit)
      return nil if unit.blank?
      
      CONVERSIONS.each do |dimension, definition|
        case definition
        when Hash
          return dimension if definition.key?(unit)
        when Array
          return dimension if definition.include?(unit)
        end
      end
      
      nil
    end

    # サポートしている全単位を返す
    # @return [Array<String>] サポートしている単位の配列
    def supported_units
      units = []
      CONVERSIONS.each_value do |definition|
        case definition
        when Hash
          units.concat(definition.keys)
        when Array
          units.concat(definition)
        end
      end
      units.uniq
    end

    # 基本単位を返す（ディメンション内で最小の単位）
    # @param dimension [Symbol] ディメンション
    # @return [String, nil] 基本単位
    def base_unit_for(dimension)
      case dimension
      when :mass
        'g'
      when :volume
        'ml'
      when :count
        '個' # 個数系はすべて等価だが、代表として '個' を返す
      else
        nil
      end
    end
  end
end