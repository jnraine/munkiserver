class TestController < ApplicationController
  filter_access_to :all
  
  def info
  end

end
