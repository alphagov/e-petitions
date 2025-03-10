class ApplicationDrop < Liquid::Drop
  class Routing
    include Rails.application.routes.url_helpers
  end

  private

  def routes
    @routes ||= Routing.new
  end
end
