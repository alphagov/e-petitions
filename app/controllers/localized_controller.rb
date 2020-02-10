class LocalizedController < ApplicationController
  if ENV['TRANSLATION_ENABLED'].present?
    before_action do
      Language.reload_translations
    end
  end

  before_action :set_locale

  private

  def set_locale
    I18n.locale = locale
  end

  def locale
    case params[:locale]
    when "cy-GB"
      :"cy-GB"
    else
      :"en-GB"
    end
  end
end
