class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card,
                only: %i[show edit update destroy schedule_review
                         mark_reviewed cancel_review]
  before_action :set_available_tags,
                only: %i[new create edit update new_from_ai preview_from_ai]

  def index
    @search_target = normalized_search_target
    @sort_order = normalized_sort_order
    @review_filter = normalized_review_filter
    @cards = current_user.cards

    @cards = @cards.search_by_keyword(params[:q], @search_target) if params[:q].present?

    if params[:tag_id].present?
      @selected_tag = current_user.tags.find_by(id: params[:tag_id])
      @cards = @cards.tagged_with(@selected_tag.id) if @selected_tag
    end

    @cards = filter_by_review_schedule(@cards)

    @cards = @cards.sorted_by(@sort_order)
    @tags = current_user.tags.order(:name)
  end

  def autocomplete
    query = params[:q].to_s.strip
    titles = []

    if query.length >= 2
      titles = current_user.cards
                           .matching_title(query)
                           .sorted_by("newest")
                           .limit(10)
                           .pluck(:title)
                           .uniq
    end

    render json: { titles: titles }
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

  def schedule_review
    if @card.schedule_review(next_review_on: review_schedule_params[:next_review_on])
      redirect_to @card, notice: "次回復習日を設定しました"
    else
      render :show, status: :unprocessable_content
    end
  end

  def mark_reviewed
    if @card.mark_reviewed(
      next_review_on: review_schedule_params[:next_review_on]
    )
      redirect_to @card, notice: "復習を記録し、次回復習日を設定しました"
    else
      render :show, status: :unprocessable_content
    end
  end

  def cancel_review
    if @card.cancel_review
      redirect_to @card, notice: "復習予定を解除しました"
    else
      render :show, status: :unprocessable_content
    end
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

  def normalized_search_target
    target = params[:search_target].to_s
    Card::SEARCH_TARGETS.include?(target) ? target : "all"
  end

  def normalized_sort_order
    sort_order = params[:sort].to_s
    Card::SORT_ORDERS.include?(sort_order) ? sort_order : "newest"
  end

  def normalized_review_filter
    review_filter = params[:review_filter].to_s
    return review_filter if Card::REVIEW_FILTERS.include?(review_filter)
    return "all" if params[:review] == "1"

    nil
  end

  def filter_by_review_schedule(cards)
    case @review_filter
    when "all" then cards.review_later
    when "due" then cards.review_due_by(Date.current)
    when "today" then cards.review_due_on(Date.current)
    when "this_week"
      cards.review_due_between(Date.current, Date.current.end_of_week)
    when "overdue" then cards.review_overdue_before(Date.current)
    else cards
    end
  end

  def review_schedule_params
    params.require(:card).permit(:next_review_on)
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
