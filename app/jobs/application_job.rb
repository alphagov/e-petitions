class ApplicationJob < ActiveJob::Base
  before_perform :reload_site
  before_perform :reload_parliament

  private

  def reload_site
    Site.reload
  end

  def reload_parliament
    Parliament.reload
  end
end
