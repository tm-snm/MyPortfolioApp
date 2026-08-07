class CardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @cards = current_user.cards.order(created_at: :desc)
  end

  def show
    @card = current_user.cards.find(params[:id])
  end

  def new
    @card = current_user.cards.build
  end

  def create
    @card = current_user.cards.build(card_params)

    if @card.save
      redirect_to root_path, notice: "カードを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def card_params
    params.require(:card).permit(:title, :body, :future_note)
  end
end
