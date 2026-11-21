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

      it "カードが0件なら作成導線を最初に示し、月別は文字でも0件と分かる" do
        get dashboard_path

        document = response.parsed_body
        first_card = document.at_css('[aria-labelledby="first-card-heading"]')
        monthly_section = document.at_css('[aria-labelledby="monthly-cards-heading"]')

        expect(response).to have_http_status(:ok)
        expect(document.css("main section h2").first.text).to eq("まだカードがありません。")
        expect(first_card.css("a").pluck("href")).to eq([ prompt_templates_path, new_from_ai_cards_path ])
        expect(first_card.at_css(".btn-primary").text).to eq("最初のカードを作成するプロンプトを選ぶ")
        expect(first_card.at_css(".btn-outline-secondary").text).to eq("AI回答を貼り付ける")
        expect(response.body).to include(
          "タグ付きのカードがまだありません。",
          "「理解できていない」に設定されたカードはありません。"
        )
        expect(monthly_section.css("li").size).to eq(6)
        expect(monthly_section.css("li .fw-semibold").map(&:text)).to all(eq("0件"))
        expect(monthly_section.css("li").last.text).to include("2026年9月（月途中）")
        expect(monthly_section.css(".progress").pluck("aria-hidden")).to all(eq("true"))
      end

      it "復習、最近作成、理解度、蓄積の順に並べ、今日の復習を独立した操作として表示する" do
        today_card = create(:card, :scheduled_for_review, user: user, title: "今日が復習日", understanding_level: nil)

        get dashboard_path

        document = response.parsed_body
        review = document.at_css('[aria-labelledby="dashboard-review-heading"]')

        expect(document.css(".dashboard-page h2").map(&:text)).to eq(
          [ "復習", "最近作成したカード", "「理解できていない」に設定したカード", "カードの蓄積" ]
        )
        expect(review.css("a").pluck("href")).to eq(
          %w[due overdue all].map { |filter| cards_path(review_filter: filter) }
        )
        expect(review.at_css(".btn-primary").text).to eq("今日の復習を見る")
        expect(review.at_css("#overdue-reviews-metric .dashboard-metric-value").text).to eq("0")
        expect(review.text).to include("復習期限を過ぎたカードはありません。", "日付未設定を含む")
        expect(document.at_css('[aria-labelledby="recent-cards-heading"]').text).to include(today_card.title)
        expect(document.at_css('[aria-labelledby="low-understanding-heading"]').text).not_to include(today_card.title)
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
