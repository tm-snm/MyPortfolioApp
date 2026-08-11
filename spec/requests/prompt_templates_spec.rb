require "rails_helper"

RSpec.describe "PromptTemplates", type: :request do
  let(:user) { create(:user) }

  let!(:prompt_template) do
    PromptTemplate.create!(
      title: "学習用テンプレート",
      category: "learning",
      description: "学習内容を整理するテンプレートです",
      body: "これはプロンプト本文です"
    )
  end

  describe "GET /prompt_templates" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "テンプレート一覧を表示できる" do
        get prompt_templates_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(prompt_template.title)
        expect(response.body).to include(prompt_template.description)
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

      it "テンプレート詳細を表示できる" do
        get prompt_template_path(prompt_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(prompt_template.title)
        expect(response.body).to include(prompt_template.description)
        expect(response.body).to include(prompt_template.body)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get prompt_template_path(prompt_template)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
