class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: %i[show edit update destroy]

  def index
    @cards = current_user.cards.order(created_at: :desc)
  end

  def show
  end

  def new
    @card = current_user.cards.build
  end

  def create
    @card = current_user.cards.build(create_card_params)

    if @card.save
      redirect_to @card, notice: "カードを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @card.update(card_params)
      redirect_to @card, notice: "カードを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
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
end
