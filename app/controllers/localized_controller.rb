class LocalizedController < ApplicationController
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
