class PromptTemplatesController < ApplicationController
  RECENTLY_USED_LIMIT = 5

  before_action :authenticate_user!
  before_action :set_available_prompt_template,
                only: %i[show favorite unfavorite record_usage]
  before_action :set_owned_prompt_template, only: %i[edit update destroy]

  def index
    available_prompt_templates = PromptTemplate.available_to(current_user)

    @prompt_templates = available_prompt_templates.order(:id)
    @favorite_prompt_templates =
      available_prompt_templates.favorited_by(current_user).order(:id)
    @recent_prompt_templates =
      available_prompt_templates
        .recently_used_by(current_user)
        .limit(RECENTLY_USED_LIMIT)
    @favorite_prompt_template_ids = @favorite_prompt_templates.ids
  end

  def show
    @favorite = current_user.prompt_template_preferences
                            .favorites
                            .exists?(prompt_template: @prompt_template)
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

  def favorite
    preference_for(@prompt_template).update!(favorite: true)

    redirect_back fallback_location: prompt_templates_path,
                  notice: "お気に入りに登録しました",
                  status: :see_other
  end

  def unfavorite
    preference = current_user.prompt_template_preferences.find_by(
      prompt_template: @prompt_template
    )

    if preference&.last_used_at?
      preference.update!(favorite: false)
    else
      preference&.destroy!
    end

    redirect_back fallback_location: prompt_templates_path,
                  notice: "お気に入りを解除しました",
                  status: :see_other
  end

  def record_usage
    preference_for(@prompt_template).update!(last_used_at: Time.current)

    head :no_content
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

  def preference_for(prompt_template)
    current_user.prompt_template_preferences.find_or_create_by!(
      prompt_template: prompt_template
    )
  end
end
