class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: %i[show edit update destroy]
  before_action :set_available_tags,
                only: %i[new create edit update new_from_ai preview_from_ai]

  def index
    @cards = current_user.cards.order(created_at: :desc)

    @cards = @cards.search_by_keyword(params[:q]) if params[:q].present?

    if params[:tag_id].present?
      @selected_tag = current_user.tags.find_by(id: params[:tag_id])
      @cards = @cards.tagged_with(@selected_tag.id) if @selected_tag
    end

    @cards = @cards.review_later if params[:review] == "1"

    @tags = current_user.tags.order(:name)
  end

  def show
  end

  def new
    @card = current_user.cards.build
  end

  def create
    @card = current_user.cards.build(create_card_params)
    @tag_names = params[:tag_names]

    Card.transaction do
      @card.save!
      assign_tags(@card)
    end

    redirect_to @card, notice: "カードを作成しました"
  rescue ActiveRecord::RecordInvalid => e
    @card.errors.add(:base, "タグの設定に失敗しました") unless e.record == @card

    if @card.raw_content.present?
      @previewed = true
      render :new_from_ai, status: :unprocessable_entity
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    Card.transaction do
      @card.update!(card_params)
      assign_tags(@card) if params.key?(:tag_names)
    end

    redirect_to @card, notice: "カードを更新しました"
  rescue ActiveRecord::RecordInvalid => e
    @card.errors.add(:base, "タグの設定に失敗しました") unless e.record == @card
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @card.destroy
    redirect_to cards_path, notice: "カードを削除しました", status: :see_other
  end

  def new_from_ai
    @card = current_user.cards.build
    @previewed = false
  end

  def preview_from_ai
    raw_content = params.dig(:card, :raw_content).to_s
    @card = current_user.cards.build(raw_content: raw_content)
    @tag_names = params[:tag_names]
    @previewed = false

    if raw_content.blank?
      @raw_content_error = "AIの出力を貼り付けてください"
      return render_ai_creation(status: :unprocessable_entity)
    end

    parsed = CardParser.new(raw_content).parse
    @card = current_user.cards.build(parsed)
    @previewed = true

    render_ai_creation
  end

  private

  def card_params
    params.require(:card).permit(:title, :body, :future_note, :status)
  end

  def create_card_params
    params.require(:card).permit(
      :title,
      :body,
      :future_note,
      :raw_content
    )
  end

  def set_card
    @card = current_user.cards.find(params[:id])
  end

  def set_available_tags
    @available_tags = current_user.tags.order(:name)
  end

  def assign_tags(card)
    CardTagAssigner.new(
      user: current_user,
      card: card,
      tag_names: params[:tag_names]
    ).call
  end

  def render_ai_creation(status: :ok)
    respond_to do |format|
      format.turbo_stream { render :preview_from_ai, status: status }
      format.html { render :new_from_ai, status: status }
    end
  end
end
