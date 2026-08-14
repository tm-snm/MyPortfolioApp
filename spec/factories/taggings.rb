FactoryBot.define do
  factory :tagging do
    association :card
    association :tag
  end
end
