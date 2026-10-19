require "rails_helper"

RSpec.describe "既存画面の操作とアクセシビリティ", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "本文へのスキップリンクと移動先を表示する" do
    get cards_path

    document = response.parsed_body
    expect(document.at_css('a[href="#main-content"]').text).to eq("本文へ移動")
    expect(document.at_css("main#main-content")["tabindex"]).to eq("-1")
  end

  it "カードの保存失敗時は入力とタグを保持し、エラーを入力欄に関連付ける" do
    expect do
      post cards_path, params: {
        card: { title: "", body: "修正前の本文", future_note: "メモ" },
        tag_names: "Rails, Docker"
      }
    end.not_to change(Card, :count)

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#card_title")["aria-invalid"]).to eq("true")
    expect(document.at_css("#card_title")["aria-describedby"]).to eq("card-errors")
    expect(document.at_css("#card-errors")["data-controller"]).to eq("focus")
    expect(document.at_css("#card_body").text).to include("修正前の本文")
    expect(document.at_css("#tag_names")["value"]).to eq("Rails, Docker")
    expect(document.at_css("#card_body")["aria-invalid"]).to be_nil
  end

  it "個人テンプレートの必須項目エラーを表示し、保存しない" do
    expect do
      post prompt_templates_path, params: {
        prompt_template: { title: "", category: "学習", body: "元の本文" }
      }
    end.not_to change(PromptTemplate, :count)

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#prompt_template_title")["aria-describedby"]).to eq("prompt-template-errors")
    expect(document.at_css("#prompt_template_body").text).to include("元の本文")
  end

  it "AIの空入力エラーはStream更新後のフォーカス先を持ち、保存しない" do
    expect do
      post preview_from_ai_cards_path,
           params: { card: { raw_content: "" } },
           headers: { "ACCEPT" => Mime[:turbo_stream].to_s }
    end.not_to change(Card, :count)

    expect(response).to have_http_status(:unprocessable_content)
    document = Nokogiri::HTML.fragment(response.body)
    expect(document.at_css('turbo-stream[target="ai_card_builder"]')).to be_present
    expect(document.at_css("#card_raw_content")["aria-describedby"]).to eq("raw-content-help")
    expect(document.at_css("#raw-content-help")["data-controller"]).to eq("focus")
  end

  it "AI解析後は結果見出しへ案内し、保存と再解析を同じフォームで制御する" do
    post preview_from_ai_cards_path, params: {
      card: { raw_content: "【タイトル】\n確認\n【本文】\n内容" }
    }

    document = response.parsed_body
    expect(document.at_css("#parsed-card-heading")["data-controller"]).to eq("focus")
    form = document.at_css('form[data-controller="form-submission"]')
    expect(form.at_css('input[value="カードを保存"]')["data-turbo-submits-with"]).to eq("保存中...")
    expect(form.at_css('input[formaction]')["formaction"]).to eq(preview_from_ai_cards_path)
  end

  it "復習予定カードの入力IDは一意で、理解度ラベルが別々の欄を参照する" do
    card = create(:card, user: user, status: :review_later)
    get card_path(card)

    document = response.parsed_body
    ids = document.css("[id]").pluck("id")
    expect(ids.uniq).to eq(ids)
    expect(document.at_css('label[for="learning_understanding_level"]').text).to include("理解度")
    expect(document.at_css('label[for="reviewed_understanding_level"]').text).to include("復習後の理解度")
    expect(document.at_css("#learning_understanding_level")["name"]).to eq("card[understanding_level]")
    expect(document.at_css("#reviewed_understanding_level")["name"]).to eq("card[understanding_level]")
  end

  it "学習状態のエラーを復習フォームへ重複表示しない" do
    card = create(:card, user: user, status: :review_later)
    patch learning_metadata_card_path(card), params: {
      card: { understanding_level: "invalid", importance: "invalid" }
    }

    document = response.parsed_body
    expect(document.css('[data-controller="focus"]').size).to eq(1)
    expect(document.at_css("#learning-errors")).to be_present
    expect(document.at_css("#reviewed-errors")).to be_nil
    expect(document.at_css("#reviewed_understanding_level")["aria-invalid"]).to be_nil
    expect(card.reload.understanding_level).to be_nil
  end

  it "復習記録のエラーは復習記録の入力だけに関連付け、DBを変更しない" do
    card = create(:card, user: user, status: :review_later, next_review_on: Date.current)
    patch mark_reviewed_card_path(card), params: {
      card: { next_review_on: "", understanding_level: "invalid" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#reviewed_next_review_on")["aria-describedby"]).to eq("reviewed-errors")
    expect(document.at_css("#reviewed_understanding_level")["aria-describedby"]).to eq("reviewed-errors")
    expect(document.at_css("#learning-errors")).to be_nil
    expect(card.reload.last_reviewed_at).to be_nil
    expect(card.next_review_on).to eq(Date.current)
  end

  it "復習日の不正入力を再表示し、保存しない" do
    card = create(:card, user: user)
    past_date = Date.current - 1
    patch schedule_review_card_path(card), params: { card: { next_review_on: past_date } }

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#card_next_review_on")["value"]).to eq(past_date.to_s)
    expect(document.at_css("#card_next_review_on")["aria-describedby"]).to eq("schedule-errors")
    expect(card.reload.next_review_on).to be_nil
  end

  it "既存のアカウント編集を日本語で表示し、誤ったパスワードでは更新しない" do
    get edit_user_registration_path
    expect(response.body).to include("アカウントを編集", "アカウントを更新")

    original_email = user.email
    put user_registration_path, params: {
      user: { email: "changed@example.com", current_password: "incorrect" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#user_current_password")["aria-invalid"]).to eq("true")
    expect(document.at_css("#user_current_password")["aria-describedby"]).to include("error_explanation")
    expect(user.reload.email).to eq(original_email)
  end

  it "アカウント削除の失敗ではFlashへ案内し、本人を削除しない" do
    delete user_registration_path, params: {
      deletion_confirmation: "1", current_password: "incorrect"
    }

    expect(response).to have_http_status(:unprocessable_content)
    document = response.parsed_body
    expect(document.at_css("#flash-alert")["data-controller"]).to eq("focus")
    expect(document.at_css("#current_password")["aria-describedby"]).to include("flash-alert")
    expect(User.exists?(user.id)).to be(true)
  end

  it "404と422の静的ページは日本語の見出しと復帰導線を持つ" do
    [ 404, 422 ].each do |code|
      document = Nokogiri::HTML(Rails.root.join("public", "#{code}.html").read)
      expect(document.at_css("html")["lang"]).to eq("ja")
      expect(document.at_css("h1").text).to be_present
      expect(document.at_css('a[href="/"]').text).to eq("トップページへ戻る")
      expect(document.at_css('meta[name="viewport"]')).to be_present
    end
  end
end
