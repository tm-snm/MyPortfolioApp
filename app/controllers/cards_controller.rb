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
    @card = current_user.cards.build(card_params)

    if @card.save
      redirect_to cards_path, notice: "カードを作成しました"
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

  private

  def card_params
    params.require(:card).permit(:title, :body, :future_note)
  end

  def set_card
    @card = current_user.cards.find(params[:id])
  end
end
