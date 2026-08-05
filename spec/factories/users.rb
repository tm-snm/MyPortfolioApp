FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user#{number}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
