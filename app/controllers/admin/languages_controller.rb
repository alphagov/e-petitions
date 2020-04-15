class Admin::LanguagesController < Admin::AdminController
  before_action :require_sysadmin
  before_action :redirect_to_admin_hub, unless: :translation_enabled?
  before_action :fetch_languages, only: %i[index]
  before_action :fetch_language, only: %i[show edit update destroy reload]
  before_action :fetch_key, only: %i[edit update destroy]
  before_action :fetch_translation, only: %i[edit]
  before_action :set_translation, only: %i[update]

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
      format.yaml {
        headers["Content-Disposition"] = "attachment; filename=ui.#{@language.locale}.yml"
      }
    end
  end

  def edit
    @key = params[:key]
    @translation = @language.get(@key)

    respond_to do |format|
      format.html
    end
  end

  def update
    if @language.set!(@key, @translation)
      redirect_to edit_admin_language_url(@language.locale, @key), notice: :key_updated
    else
      respond_to do |format|
        format.html { render :edit, alert: :key_not_updated }
      end
    end
  end

  def destroy
    if @language.delete!(@key)
      redirect_to admin_language_url(@language.locale), notice: :key_deleted
    else
      redirect_to admin_language_url(@language.locale), alert: :key_not_deleted
    end
  end

  def reload
    if @language.reload_translations
      redirect_to admin_languages_url, notice: :language_reloaded
    else
      redirect_to admin_languages_url, alert: :language_not_reloaded
    end
  end

  private

  def translation_enabled?
    Site.translation_enabled?
  end

  def redirect_to_admin_hub
    redirect_to admin_root_url, notice: "Editing of languages is disabled"
  end

  def fetch_languages
    @languages = Language.by_name
  end

  def fetch_language
    @language = Language.find_by!(locale: params[:locale])
  end

  def fetch_key
    @key = params[:key]

    unless @language.key?(@key)
      @language.set(@key, I18n.translate(@key, locale: @language.locale))
    end
  end

  def fetch_translation
    @translation = @language.get(@key)
  end

  def set_translation
    @translation = params[:translation]
  end
end
