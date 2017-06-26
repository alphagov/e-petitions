class PingController < ApplicationController
  skip_before_action :service_unavailable
  skip_before_action :authenticate

  def ping
    render plain: "PONG"
  end
end
