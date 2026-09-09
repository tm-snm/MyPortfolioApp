FactoryBot.define do
  factory :prompt_template_preference do
    association :user
    association :prompt_template
    favorite { false }
    last_used_at { nil }
  end
end
