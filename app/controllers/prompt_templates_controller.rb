class PromptTemplatesController < ApplicationController
  before_action :authenticate_user!

  def index
    @prompt_templates = PromptTemplate.order(:id)
  end

  def show
    @prompt_template = PromptTemplate.find(params[:id])
  end
end
