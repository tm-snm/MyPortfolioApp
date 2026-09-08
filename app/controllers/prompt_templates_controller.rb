class PromptTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_available_prompt_template, only: :show
  before_action :set_owned_prompt_template, only: %i[edit update destroy]

  def index
    @prompt_templates = PromptTemplate.available_to(current_user).order(:id)
  end

  def show
  end

  def new
    @prompt_template = current_user.prompt_templates.build
  end

  def create
    @prompt_template = current_user.prompt_templates.build(prompt_template_params)

    if @prompt_template.save
      redirect_to @prompt_template, notice: "個人テンプレートを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prompt_template.update(prompt_template_params)
      redirect_to @prompt_template, notice: "個人テンプレートを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prompt_template.destroy
    redirect_to prompt_templates_path,
                notice: "個人テンプレートを削除しました",
                status: :see_other
  end

  private

  def prompt_template_params
    params.require(:prompt_template).permit(
      :title,
      :category,
      :description,
      :body
    )
  end

  def set_available_prompt_template
    @prompt_template = PromptTemplate.available_to(current_user).find(params[:id])
  end

  def set_owned_prompt_template
    @prompt_template = current_user.prompt_templates.find(params[:id])
  end
end
