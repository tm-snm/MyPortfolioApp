require "rails_helper"

RSpec.describe "Learning metadata", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, user: user) }

  describe "GET /cards/:id" do
    before do
      sign_in user
    end

    it "理解度と重要度の現在値と選択肢を表示する" do
      card.update!(
        understanding_level: :mostly_understood,
        importance: :high
      )

      get card_path(card)

      document = response.parsed_body
      understanding_options =
        document.css('select[name="card[understanding_level]"] option')
      importance_options =
        document.css('select[name="card[importance]"] option')

      expect(response).to have_http_status(:ok)
      expect(understanding_options.pluck("value")).to eq(
        [ "", "not_understood", "mostly_understood", "can_explain" ]
      )
      expect(importance_options.pluck("value")).to eq(
        [ "", "low", "medium", "high" ]
      )
      expect(
        document.at_css(
          'select[name="card[understanding_level]"] option[selected]'
        )["value"]
      ).to eq("mostly_understood")
      expect(
        document.at_css(
          'select[name="card[importance]"] option[selected]'
        )["value"]
      ).to eq("high")
      expect(response.body).to include(
        "理解度：だいたい理解",
        "重要度：高"
      )
    end
  end

  describe "GET /cards" do
    before do
      sign_in user
    end

    it "自分のカードごとに理解度と重要度を表示する" do
      own_card = create(
        :card,
        user: user,
        title: "自分の学習状態カード",
        understanding_level: :can_explain,
        importance: :medium
      )
      create(
        :card,
        user: other_user,
        title: "他ユーザーの学習状態カード",
        understanding_level: :not_understood,
        importance: :high
      )

      get cards_path

      document = response.parsed_body
      own_card_element = document.css("article").find do |element|
        element.text.include?(own_card.title)
      end

      expect(own_card_element.text).to include(
        "理解度：説明できる",
        "重要度：中"
      )
      expect(response.body).not_to include("他ユーザーの学習状態カード")
    end
  end

  describe "PATCH /cards/:id/learning_metadata" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "理解度と重要度を更新する" do
        patch learning_metadata_card_path(card), params: {
          card: {
            understanding_level: "mostly_understood",
            importance: "high"
          }
        }

        expect(card.reload).to have_attributes(
          understanding_level: "mostly_understood",
          importance: "high"
        )
        expect(response).to redirect_to(card_path(card))
      end

      it "理解度と重要度を未設定へ戻す" do
        card.update!(
          understanding_level: :can_explain,
          importance: :medium
        )

        patch learning_metadata_card_path(card), params: {
          card: {
            understanding_level: "",
            importance: ""
          }
        }

        expect(card.reload).to have_attributes(
          understanding_level: nil,
          importance: nil
        )
        expect(response).to redirect_to(card_path(card))
      end

      it "定義外の値は保存しない" do
        card.update!(
          understanding_level: :not_understood,
          importance: :low
        )

        patch learning_metadata_card_path(card), params: {
          card: {
            understanding_level: "invalid",
            importance: "invalid"
          }
        }

        expect(card.reload).to have_attributes(
          understanding_level: "not_understood",
          importance: "low"
        )
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          "理解度は一覧にありません",
          "重要度は一覧にありません"
        )
      end

      it "許可していない属性は更新しない" do
        original_title = card.title

        patch learning_metadata_card_path(card), params: {
          card: {
            understanding_level: "can_explain",
            importance: "medium",
            title: "不正に変更されたタイトル",
            status: "review_later"
          }
        }

        expect(card.reload).to have_attributes(
          title: original_title,
          status: "normal",
          understanding_level: "can_explain",
          importance: "medium"
        )
      end

      it "他ユーザーのカードを更新しない" do
        other_card = create(:card, user: other_user)

        patch learning_metadata_card_path(other_card), params: {
          card: {
            understanding_level: "can_explain",
            importance: "high"
          }
        }

        expect(other_card.reload).to have_attributes(
          understanding_level: nil,
          importance: nil
        )
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトし、更新しない" do
        patch learning_metadata_card_path(card), params: {
          card: {
            understanding_level: "can_explain",
            importance: "high"
          }
        }

        expect(card.reload).to have_attributes(
          understanding_level: nil,
          importance: nil
        )
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
