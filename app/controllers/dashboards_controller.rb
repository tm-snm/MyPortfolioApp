class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @dashboard = DashboardMetrics.new(
      cards: current_user.cards,
      tags: current_user.tags
    ).call
  end
end
