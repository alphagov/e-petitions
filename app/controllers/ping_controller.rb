class PingController < ApplicationController
  def ping
    render text: "PONG"
  end
end
