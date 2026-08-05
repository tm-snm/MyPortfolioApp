class CardsController < ApplicationController
  before_action :authenticate_user!

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
