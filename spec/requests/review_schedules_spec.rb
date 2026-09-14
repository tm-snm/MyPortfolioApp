require "rails_helper"

RSpec.describe "Review schedules", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2026, 9, 9, 12, 0)) { example.run }
  end

  describe "GET /cards" do
    let!(:overdue_card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "期限超過カード",
        next_review_on: Date.current.yesterday
      )
    end
    let!(:today_card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "今日のカード",
        next_review_on: Date.current
      )
    end
    let!(:this_week_card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "今週のカード",
        next_review_on: Date.current.end_of_week
      )
    end
    let!(:later_card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "来週以降のカード",
        next_review_on: Date.current.end_of_week + 1.day
      )
    end
    let!(:unscheduled_card) do
      create(
        :card,
        user: user,
        title: "日付未設定カード",
        status: :review_later
      )
    end
    let!(:normal_card) do
      create(:card, user: user, title: "通常カード")
    end
    let!(:other_user_card) do
      create(
        :card,
        :scheduled_for_review,
        user: other_user,
        title: "他ユーザーの期限カード",
        next_review_on: Date.current
      )
    end

    before do
      sign_in user
    end

    it "復習状況の選択肢を表示する" do
      get cards_path

      document = response.parsed_body
      options = document.css('select[name="review_filter"] option')

      expect(options.pluck("value")).to eq(
        [ "", "all", "due", "today", "this_week", "overdue" ]
      )
    end

    it "復習予定すべてには日付未設定を含める" do
      get cards_path, params: { review_filter: "all" }

      expect(response.body).to include(
        overdue_card.title,
        today_card.title,
        this_week_card.title,
        later_card.title,
        unscheduled_card.title
      )
      expect(response.body).not_to include(
        normal_card.title,
        other_user_card.title
      )
    end

    it "今日までには期限超過と今日のカードだけを表示する" do
      get cards_path, params: { review_filter: "due" }

      expect(response.body).to include(overdue_card.title, today_card.title)
      expect(response.body).not_to include(
        this_week_card.title,
        later_card.title,
        unscheduled_card.title,
        normal_card.title,
        other_user_card.title
      )
    end

    it "今日のカードだけを表示する" do
      get cards_path, params: { review_filter: "today" }

      expect(response.body).to include(today_card.title)
      expect(response.body).not_to include(
        overdue_card.title,
        this_week_card.title,
        other_user_card.title
      )
    end

    it "今日から今週末までのカードを表示する" do
      get cards_path, params: { review_filter: "this_week" }

      expect(response.body).to include(today_card.title, this_week_card.title)
      expect(response.body).not_to include(
        overdue_card.title,
        later_card.title,
        other_user_card.title
      )
    end

    it "期限超過カードだけを表示する" do
      get cards_path, params: { review_filter: "overdue" }

      expect(response.body).to include(overdue_card.title)
      expect(response.body).not_to include(
        today_card.title,
        this_week_card.title,
        other_user_card.title
      )
    end

    it "既存のreview=1を復習予定すべてとして扱う" do
      get cards_path, params: { review: "1" }

      expect(response.body).to include(unscheduled_card.title)
      expect(response.body).not_to include(normal_card.title)
    end

    it "不明な絞り込み値では復習条件を適用しない" do
      get cards_path, params: { review_filter: "invalid" }

      expect(response.body).to include(normal_card.title, overdue_card.title)
      expect(response.body).not_to include(other_user_card.title)
    end
  end

  describe "PATCH /cards/:id/schedule_review" do
    let(:card) { create(:card, user: user) }

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "次回復習日を設定して復習予定にする" do
        next_review_on = Date.current + 1.day

        patch schedule_review_card_path(card), params: {
          card: { next_review_on: next_review_on }
        }

        expect(card.reload).to have_attributes(
          status: "review_later",
          next_review_on: next_review_on
        )
        expect(response).to redirect_to(card_path(card))
      end

      it "次回復習日が空なら保存しない" do
        patch schedule_review_card_path(card), params: {
          card: { next_review_on: "" }
        }

        expect(card.reload).to have_attributes(
          status: "normal",
          next_review_on: nil
        )
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "過去日なら保存しない" do
        patch schedule_review_card_path(card), params: {
          card: { next_review_on: Date.current.yesterday }
        }

        expect(card.reload).to have_attributes(
          status: "normal",
          next_review_on: nil
        )
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "他ユーザーのカードを変更しない" do
        other_card = create(:card, user: other_user)

        patch schedule_review_card_path(other_card), params: {
          card: { next_review_on: Date.current }
        }

        expect(other_card.reload).to be_normal
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトして保存しない" do
        patch schedule_review_card_path(card), params: {
          card: { next_review_on: Date.current }
        }

        expect(card.reload).to be_normal
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /cards/:id/mark_reviewed" do
    let(:card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        next_review_on: Date.current
      )
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "復習日時と次回復習日を同時に保存する" do
        next_review_on = Date.current + 1.week

        patch mark_reviewed_card_path(card), params: {
          card: {
            next_review_on: next_review_on,
            understanding_level: "mostly_understood"
          }
        }

        expect(card.reload).to have_attributes(
          status: "review_later",
          next_review_on: next_review_on,
          last_reviewed_at: Time.current,
          understanding_level: "mostly_understood"
        )
        expect(response).to redirect_to(card_path(card))
      end

      it "次回復習日が空ならどちらも保存しない" do
        original_next_review_on = card.next_review_on

        patch mark_reviewed_card_path(card), params: {
          card: { next_review_on: "" }
        }

        expect(card.reload).to have_attributes(
          next_review_on: original_next_review_on,
          last_reviewed_at: nil
        )
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "理解度が不正なら復習情報も理解度も保存しない" do
        original_next_review_on = card.next_review_on

        patch mark_reviewed_card_path(card), params: {
          card: {
            next_review_on: Date.current + 1.week,
            understanding_level: "invalid"
          }
        }

        expect(card.reload).to have_attributes(
          next_review_on: original_next_review_on,
          last_reviewed_at: nil,
          understanding_level: nil
        )
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("理解度は一覧にありません")
      end

      it "他ユーザーのカードを変更しない" do
        other_card = create(
          :card,
          :scheduled_for_review,
          user: other_user
        )

        patch mark_reviewed_card_path(other_card), params: {
          card: { next_review_on: Date.current + 1.week }
        }

        expect(other_card.reload.last_reviewed_at).to be_nil
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトして保存しない" do
        patch mark_reviewed_card_path(card), params: {
          card: { next_review_on: Date.current + 1.week }
        }

        expect(card.reload.last_reviewed_at).to be_nil
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /cards/:id/cancel_review" do
    let(:last_reviewed_at) { 1.day.ago }
    let(:card) do
      create(
        :card,
        :scheduled_for_review,
        user: user,
        last_reviewed_at: last_reviewed_at
      )
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "復習予定を解除し最終復習日時は保持する" do
        delete cancel_review_card_path(card)

        expect(card.reload).to have_attributes(
          status: "normal",
          next_review_on: nil,
          last_reviewed_at: last_reviewed_at
        )
        expect(response).to redirect_to(card_path(card))
      end

      it "他ユーザーのカードを変更しない" do
        other_card = create(
          :card,
          :scheduled_for_review,
          user: other_user
        )

        delete cancel_review_card_path(other_card)

        expect(other_card.reload).to be_review_later
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトして解除しない" do
        delete cancel_review_card_path(card)

        expect(card.reload).to be_review_later
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
