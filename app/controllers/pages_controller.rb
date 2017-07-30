class PagesController < ApplicationController
  def index
    respond_to do |format|
      format.html
    end
  end

  def help
    respond_to do |format|
      format.html
    end
  end

  def privacy
    respond_to do |format|
      format.html
    end
  end

  def browserconfig
    respond_to do |format|
      format.xml
    end
  end

  def manifest
    respond_to do |format|
      format.json
    end
  end
end
