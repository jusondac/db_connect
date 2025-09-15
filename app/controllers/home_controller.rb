class HomeController < ApplicationController
  def index
    @tables = session[:tables] || []
  end
end
