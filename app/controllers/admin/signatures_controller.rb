class Admin::SignaturesController < Admin::AdminController
  before_action :fetch_signature, except: :index

  def index
    @query = params.fetch(:q, '')
    @search_type = "signature"
    @signatures = Signature.send(search_query_method, @query).paginate(page: params[:page], per_page: 50)
  end

  def validate
    begin
      @signature.validate!
      redirect_to admin_signatures_url(q: params[:q]), notice: :signature_validated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_signatures_url(q: params[:q]), alert: :signature_not_validated
    end
  end

  def invalidate
    begin
      @signature.invalidate!
      redirect_to admin_signatures_url(q: params[:q]), notice: :signature_invalidated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_signatures_url(q: @signature.email), alert: :signature_not_invalidated
    end
  end

  def destroy
    if @signature.destroy
      redirect_to admin_signatures_url(q: params[:q]), notice: :signature_deleted
    else
      redirect_to admin_signatures_url(q: params[:q]), alert: :signature_not_deleted
    end
  end

  private

  def fetch_signature
    @signature = Signature.find(params[:id])
  end

  def search_query_method
    if query_is_ip?
      :for_ip
    elsif query_is_email?
      :for_email
    else
      :for_name
    end
  end

  def query_is_ip?
    /\A(?:\d{1,3}){1}(?:\.\d{1,3}){3}\z/ =~ @query
  end

  def query_is_email?
    @query.include?('@')
  end
end
