class MessageAnalyzerService
  # 検出優先度: recipe > shopping > ingredients > help
  COMMAND_PATTERNS = {
    recipe: [
      /(レシピ|料理|献立|recipe)/i,
      /(何作る|何作ろう|何を作ろう|何料理)/i,
      /(作り方|調理)/i
    ],
    shopping: [
      /(買い物|買うもの|不足|shopping)/i,
      /(購入|足りない|買い出し|スーパー)/i
    ],
    ingredients: [
      /(在庫|食材|何がある|冷蔵庫|ingredients)/i,
      /(持ってる|残ってる)/i,
      /(食べ物|材料)/i
    ],
    help: [
      /(ヘルプ|使い方|help|\?)/i,
      /(分からない|わからない)/i,
      /(どうやって|方法)/i
    ]
  }.freeze

  def initialize(message_text)
    @message_text = message_text.to_s.strip
  end

  def analyze
    return :greeting if greeting_message?
    return :unknown if @message_text.empty?

    detected_command = detect_command
    detected_command || :unknown
  end

  def greeting_message?
    greeting_patterns = [
      /こんにちは|こんばんは|おはよう/i,
      /hello|hi|hey/i,
      /はじめまして|初めまして/i
    ]

    greeting_patterns.any? { |pattern| @message_text.match?(pattern) }
  end

  private

  def detect_command
    COMMAND_PATTERNS.each do |command, patterns|
      if patterns.any? { |pattern| @message_text.match?(pattern) }
        return command
      end
    end
    nil
  end
end
