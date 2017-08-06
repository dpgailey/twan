class HomeController < ApplicationController
  def index
    @accounts = Account.order('followers_count/friends_count DESC')
  end
end
