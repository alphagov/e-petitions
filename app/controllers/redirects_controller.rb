class RedirectsController < ApplicationController
  def home
    http_cache_forever(public: true) do
      redirect_to home_url, status: :moved_permanently
    end
  end

  def help
    http_cache_forever(public: true) do
      redirect_to help_url, status: :moved_permanently
    end
  end

  def privacy
    http_cache_forever(public: true) do
      redirect_to privacy_url, status: :moved_permanently
    end
  end

  def national_archives
    http_cache_forever(public: true) do
      redirect_to national_archives_url, status: :moved_permanently, allow_other_host: true
    end
  end

  def standards
    http_cache_forever(public: true) do
      redirect_to standards_url, status: :moved_permanently
    end
  end
end
