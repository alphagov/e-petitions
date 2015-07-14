class PingController < ApplicationController
  skip_before_action :service_unavailable
  skip_before_action :authenticate

  def ping
    render text: "PONG"
  end
end
