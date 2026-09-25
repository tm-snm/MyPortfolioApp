require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2026, 9, 19, 12, 0)) { example.run }
  end

  describe "GET /dashboard" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の集計とカード・タグだけを表示する" do
        own_card = create(
          :card,
          :scheduled_for_review,
          user: user,
          title: "自分の期限超過カード",
          next_review_on: Date.current.yesterday,
          understanding_level: :not_understood,
          created_at: Time.current
        )
        own_tag = create(:tag, user: user, name: "Rails")
        create(:tagging, card: own_card, tag: own_tag)

        other_card = create(
          :card,
          :scheduled_for_review,
          user: other_user,
          title: "他ユーザーの秘密カード",
          next_review_on: Date.current.yesterday,
          understanding_level: :not_understood,
          created_at: Time.current
        )
        other_tag = create(:tag, user: other_user, name: "秘密タグ")
        create(:tagging, card: other_card, tag: other_tag)

        get dashboard_path

        document = response.parsed_body

        expect(response).to have_http_status(:ok)
        expect(document.at_css("#total-cards-metric .dashboard-metric-value").text.strip).to eq("1")
        expect(document.at_css("#cards-this-month-metric .dashboard-metric-value").text.strip).to eq("1")
        expect(document.at_css("#review-scheduled-metric .dashboard-metric-value").text.strip).to eq("1")
        expect(document.at_css("#overdue-reviews-metric .dashboard-metric-value").text.strip).to eq("1")
        expect(response.body).to include(own_card.title, own_tag.name)
        expect(response.body).not_to include(other_card.title, other_tag.name)
      end

      it "カードがなくても空状態と6か月分の0件を表示する" do
        get dashboard_path

        document = response.parsed_body
        progressbars = document.css('[role="progressbar"]')

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          "まだカードがありません。",
          "タグ付きのカードがまだありません。",
          "「理解できていない」に設定されたカードはありません。"
        )
        expect(progressbars.size).to eq(6)
        expect(progressbars.pluck("aria-valuenow")).to all(eq("0"))
      end

      it "既存の絞り込み画面へ移動するリンクを表示する" do
        get dashboard_path

        document = response.parsed_body

        expect(
          document.at_css(
            "a[href='#{cards_path(review_filter: "all")}']"
          ).text.strip
        ).to eq("復習予定のカードを見る")
        expect(
          document.at_css(
            "a[href='#{cards_path(review_filter: "overdue")}']"
          ).text.strip
        ).to eq("期限超過のカードを見る")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        get dashboard_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
