require "rails_helper"

RSpec.describe "PromptTemplates", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let!(:official_template) do
    create(
      :prompt_template,
      title: "公式テンプレート",
      category: "official"
    )
  end

  let!(:personal_template) do
    create(
      :prompt_template,
      :personal,
      user: user,
      title: "自分の個人テンプレート",
      category: "personal"
    )
  end

  let!(:other_users_template) do
    create(
      :prompt_template,
      :personal,
      user: other_user,
      title: "他人の個人テンプレート",
      category: "private"
    )
  end

  let(:valid_params) do
    {
      prompt_template: {
        title: "エラー調査用テンプレート",
        category: "技術調査",
        description: "エラーの原因と解決方法を整理する",
        body: "この会話から原因と解決方法を整理してください。"
      }
    }
  end

  describe "GET /prompt_templates" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "公式テンプレートと自分の個人テンプレートを表示する" do
        get prompt_templates_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(official_template.title)
        expect(response.body).to include(personal_template.title)
      end

      it "他ユーザーの個人テンプレートを表示しない" do
        get prompt_templates_path

        expect(response.body).not_to include(other_users_template.title)
      end

      it "公式テンプレートと個人テンプレートを区別して表示する" do
        get prompt_templates_path

        document = response.parsed_body
        cards = document.css(".card")
        official_card = cards.find do |card|
          card.text.include?(official_template.title)
        end
        personal_card = cards.find do |card|
          card.text.include?(personal_template.title)
        end

        expect(official_card.text).to include("公式")
        expect(personal_card.text).to include("個人")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get prompt_templates_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "公式テンプレートを表示できる" do
        get prompt_template_path(official_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(official_template.title)
        expect(response.body).to include("プロンプトをコピー")
      end

      it "自分の個人テンプレートを表示できる" do
        get prompt_template_path(personal_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(personal_template.title)
        expect(response.body).to include("編集")
        expect(response.body).to include("削除")
      end

      it "公式テンプレートには編集・削除導線を表示しない" do
        get prompt_template_path(official_template)

        document = response.parsed_body

        expect(
          document.at_css(
            "a[href='#{edit_prompt_template_path(official_template)}']"
          )
        ).to be_nil
        expect(
          document.at_css(
            "form[action='#{prompt_template_path(official_template)}']"
          )
        ).to be_nil
      end

      it "他ユーザーの個人テンプレートを表示できない" do
        get prompt_template_path(other_users_template)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get prompt_template_path(official_template)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/new" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "個人テンプレート作成画面を表示できる" do
        get new_prompt_template_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("個人テンプレートを作成")
        expect(response.body).to include('name="prompt_template[title]"')
        expect(response.body).to include('name="prompt_template[body]"')
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get new_prompt_template_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /prompt_templates" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "ログインユーザーの個人テンプレートを作成する" do
        expect do
          post prompt_templates_path, params: valid_params
        end.to change { user.prompt_templates.count }.by(1)

        created_template = user.prompt_templates.order(:created_at).last

        expect(created_template).to have_attributes(
          title: "エラー調査用テンプレート",
          category: "技術調査",
          description: "エラーの原因と解決方法を整理する",
          body: "この会話から原因と解決方法を整理してください。"
        )
        expect(response).to redirect_to(
          prompt_template_path(created_template)
        )
      end

      it "送信されたuser_idで所有者を変更できない" do
        forged_params = valid_params.deep_dup
        forged_params[:prompt_template][:user_id] = other_user.id

        post prompt_templates_path, params: forged_params

        expect(user.prompt_templates.order(:created_at).last.user).to eq(user)
      end

      it "不正な入力では個人テンプレートを作成しない" do
        invalid_params = valid_params.deep_dup
        invalid_params[:prompt_template][:title] = ""

        expect do
          post prompt_templates_path, params: invalid_params
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("タイトルを入力してください")
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを作成せずログイン画面へリダイレクトする" do
        expect do
          post prompt_templates_path, params: valid_params
        end.not_to change(PromptTemplate, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/:id/edit" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレート編集画面を表示できる" do
        get edit_prompt_template_path(personal_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(personal_template.title)
      end

      it "他ユーザーの個人テンプレートを編集できない" do
        get edit_prompt_template_path(other_users_template)

        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを編集できない" do
        get edit_prompt_template_path(official_template)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get edit_prompt_template_path(personal_template)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレートを更新する" do
        patch prompt_template_path(personal_template), params: valid_params

        expect(personal_template.reload).to have_attributes(
          title: "エラー調査用テンプレート",
          category: "技術調査",
          description: "エラーの原因と解決方法を整理する",
          body: "この会話から原因と解決方法を整理してください。"
        )
        expect(response).to redirect_to(
          prompt_template_path(personal_template)
        )
      end

      it "不正な入力では個人テンプレートを更新しない" do
        original_title = personal_template.title
        invalid_params = valid_params.deep_dup
        invalid_params[:prompt_template][:title] = ""

        patch prompt_template_path(personal_template), params: invalid_params

        expect(personal_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("タイトルを入力してください")
      end

      it "他ユーザーの個人テンプレートを更新できない" do
        original_title = other_users_template.title

        patch prompt_template_path(other_users_template), params: valid_params

        expect(other_users_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを更新できない" do
        original_title = official_template.title

        patch prompt_template_path(official_template), params: valid_params

        expect(official_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを更新せずログイン画面へリダイレクトする" do
        original_title = personal_template.title

        patch prompt_template_path(personal_template), params: valid_params

        expect(personal_template.reload.title).to eq(original_title)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレートを削除する" do
        personal_template

        expect do
          delete prompt_template_path(personal_template)
        end.to change(PromptTemplate, :count).by(-1)

        expect(response).to redirect_to(prompt_templates_path)
        expect(response).to have_http_status(:see_other)
      end

      it "他ユーザーの個人テンプレートを削除できない" do
        other_users_template

        expect do
          delete prompt_template_path(other_users_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを削除できない" do
        official_template

        expect do
          delete prompt_template_path(official_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを削除せずログイン画面へリダイレクトする" do
        personal_template

        expect do
          delete prompt_template_path(personal_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
