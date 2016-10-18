class ApplicationJob < ActiveJob::Base
  before_perform :reload_site

  private

  def reload_site
    Site.reload
  end
end
