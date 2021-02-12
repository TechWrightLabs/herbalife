class HomeController < ApplicationController
  def index
    @user = User.new
  end

  def thanks
    @user = User.find params[:id]
  end
end