FactoryBot.define do
  factory :fridge_image do
    association :user
    association :line_account
    sequence(:line_message_id) { |n| "#{Time.current.to_i}#{n}" }
    status { 'pending' }
    recognized_ingredients { [] }
    image_metadata { {} }
    captured_at { Time.current }

    trait :pending do
      status { 'pending' }
      recognized_ingredients { [] }
      recognized_at { nil }
      error_message { nil }
    end

    trait :processing do
      status { 'processing' }
      recognized_ingredients { [] }
      recognized_at { nil }
      error_message { nil }
    end

    trait :completed do
      status { 'completed' }
      recognized_ingredients do
        [
          {
            name: 'トマト',
            confidence: 0.85,
            detected_at: Time.current.iso8601
          },
          {
            name: '玉ねぎ',
            confidence: 0.75,
            detected_at: Time.current.iso8601
          }
        ]
      end
      image_metadata do
        {
          texts: { full_text: '2024/12/31' },
          processing_duration: 2.5,
          api_version: 'v1',
          features_used: %w[label object text]
        }
      end
      recognized_at { Time.current }
      error_message { nil }
    end

    trait :failed do
      status { 'failed' }
      recognized_ingredients { [] }
      recognized_at { Time.current }
      error_message { 'API Error: Rate limit exceeded' }
    end

    trait :from_line do
      association :line_account
      line_message_id { "575349651848036746" }
    end

    trait :from_web do
      association :user
      line_account { nil }
      line_message_id { nil }
    end

    trait :with_ingredients do
      completed
    end

    trait :without_ingredients do
      status { 'completed' }
      recognized_ingredients { [] }
      recognized_at { Time.current }
    end
  end
end
