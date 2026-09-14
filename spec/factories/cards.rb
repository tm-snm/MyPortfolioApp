FactoryBot.define do
  factory :card do
    association :user

    title { "Railsのmigrationで詰まった" }
    body { "migrationファイルを確認してからdb:migrateを実行する。" }
    future_note { "まずdb:migrate:statusを確認する。" }
    raw_content { nil }
    status { :normal }
    next_review_on { nil }
    last_reviewed_at { nil }
    understanding_level { nil }
    importance { nil }

    trait :scheduled_for_review do
      status { :review_later }
      next_review_on { Date.current }
    end
  end
end
