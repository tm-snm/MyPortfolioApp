require "rails_helper"

RSpec.describe "カード検索", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }

  it "検索条件を組み合わせてURLへ保持し、一括解除できる" do
    rails_tag = create(:tag, user: user, name: "Rails")
    old_card = create(
      :card,
      user: user,
      title: "Railsの古いカード",
      status: :review_later,
      created_at: 2.days.ago
    )
    new_card = create(
      :card,
      user: user,
      title: "Railsの新しいカード",
      status: :review_later,
      created_at: 1.day.ago
    )
    body_only_card = create(
      :card,
      user: user,
      title: "本文だけ一致するカード",
      body: "Railsについて",
      status: :review_later
    )
    other_user_card = create(
      :card,
      title: "Railsの他ユーザーカード",
      status: :review_later
    )

    [ old_card, new_card, body_only_card ].each do |card|
      create(:tagging, card: card, tag: rails_tag)
    end

    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    fill_in "キーワード", with: "Rails"
    select "タイトル", from: "検索対象"
    select "Rails", from: "タグ"
    check "復習予定のみ"
    select "古い順", from: "並び順"
    click_button "絞り込む"

    query_params = Rack::Utils.parse_nested_query(
      URI.parse(page.current_url).query
    )

    expect(query_params).to include(
      "q" => "Rails",
      "search_target" => "title",
      "tag_id" => rails_tag.id.to_s,
      "review" => "1",
      "sort" => "oldest"
    )
    expect(page).to have_field("キーワード", with: "Rails")
    expect(page).to have_select("検索対象", selected: "タイトル")
    expect(page).to have_select("タグ", selected: "Rails")
    expect(page).to have_checked_field("復習予定のみ")
    expect(page).to have_select("並び順", selected: "古い順")
    expect(page).to have_content(old_card.title)
    expect(page).to have_content(new_card.title)
    expect(page).not_to have_content(body_only_card.title)
    expect(page).not_to have_content(other_user_card.title)
    expect(page.body.index(old_card.title)).to be < page.body.index(new_card.title)

    click_link "条件を解除"

    expect(URI.parse(page.current_url).query).to be_nil
    expect(find_field("キーワード").value).to be_nil
    expect(page).to have_select("検索対象", selected: "すべて")
    expect(page).to have_select("並び順", selected: "新しい順")
  end
end
