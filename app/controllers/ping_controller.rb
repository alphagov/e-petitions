class PingController < ApplicationController
  def ping
    render plain: "PONG"
  end
end
