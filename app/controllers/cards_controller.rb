class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: %i[show edit update destroy]

  def index
    @cards = current_user.cards.order(created_at: :desc)
    @tags = current_user.tags.order(:name)

    @cards = @cards.search_by_keyword(params[:q]) if params[:q].present?

    if params[:tag_id].present?
      @selected_tag = current_user.tags.find_by(id: params[:tag_id])

      if @selected_tag
        @cards = @cards
          .joins(:tags)
          .where(tags: { id: @selected_tag.id })
          .distinct
      end
    end
  end

  def show
  end

  def new
    @card = current_user.cards.build
  end

  def create
    @card = current_user.cards.build(create_card_params)

    Card.transaction do
      @card.save!
      assign_tags(@card)
    end

    redirect_to @card, notice: "カードを作成しました"
  rescue ActiveRecord::RecordInvalid => e
    @card.errors.add(:base, "タグの設定に失敗しました") unless e.record == @card
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    Card.transaction do
      @card.update!(card_params)
      assign_tags(@card)
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
  end

  def preview_from_ai
    raw_content = params[:raw_content].to_s

    if raw_content.blank?
      flash.now[:alert] = "AIの出力を貼り付けてください"
      return render :new_from_ai, status: :unprocessable_entity
    end

    parsed = CardParser.new(raw_content).parse
    @card = current_user.cards.build(parsed)

    render :preview_from_ai
  end

  private

  def card_params
    params.require(:card).permit(:title, :body, :future_note)
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

  def normalized_tag_names
    params[:tag_names].to_s
                      .split(",")
                      .map(&:strip)
                      .reject(&:blank?)
                      .uniq
  end

  def assign_tags(card)
    tags = normalized_tag_names.map do |name|
      current_user.tags.find_or_create_by!(name: name)
    end

    card.tags = tags
  end
end
