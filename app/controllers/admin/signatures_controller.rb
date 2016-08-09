class Admin::SignaturesController < Admin::AdminController
  before_action :fetch_signature

  def validate
    begin
      @signature.validate!
      redirect_to admin_search_url(q: params[:q]), notice: :signature_validated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_search_url(q: params[:q]), alert: :signature_not_validated
    end
  end

  def invalidate
    begin
      @signature.invalidate!
      redirect_to admin_search_url(q: params[:q]), notice: :signature_invalidated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_search_url(q: @signature.email), alert: :signature_not_invalidated
    end
  end

  def destroy
    if @signature.destroy
      redirect_to admin_search_url(q: params[:q]), notice: :signature_deleted
    else
      redirect_to admin_search_url(q: params[:q]), alert: :signature_not_deleted
    end
  end

  private

  def fetch_signature
    @signature = Signature.find(params[:id])
  end
end
