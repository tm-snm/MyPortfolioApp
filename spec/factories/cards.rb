FactoryBot.define do
  factory :card do
    association :user

    title { "Railsのmigrationで詰まった" }
    body { "migrationファイルを確認してからdb:migrateを実行する。" }
    future_note { "まずdb:migrate:statusを確認する。" }
    raw_content { nil }
    status { :normal }
  end
end
