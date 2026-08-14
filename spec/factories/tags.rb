FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "タグ#{n}" }
  end
end
