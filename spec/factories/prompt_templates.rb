FactoryBot.define do
  factory :prompt_template do
    title { "MyString" }
    category { "MyString" }
    description { "MyText" }
    body { "MyText" }

    trait :personal do
      association :user
    end
  end
end
