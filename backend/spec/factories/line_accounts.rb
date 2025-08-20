FactoryBot.define do
  factory :line_account do
    sequence(:line_user_id) { |n| "U#{SecureRandom.hex(16)}#{n}" }
    line_display_name { Faker::Name.name }
    line_picture_url { Faker::Internet.url(host: 'cdn.line.me', path: '/profile.jpg') }

    trait :linked do
      association :user
      linked_at { Time.current }
    end

    trait :unlinked do
      user { nil }
      linked_at { nil }
    end
  end
end