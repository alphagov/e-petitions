class Admin::SignaturesController < Admin::AdminController
  before_action :fetch_signature, except: [:index]
  before_action :fetch_signatures, only: [:index]

  def index
    respond_to do |format|
      format.html
    end
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

  def fetch_signatures
    @signatures = Signature.search(params[:q], page: params[:page])
  end

  def fetch_signature
    @signature = Signature.find(params[:id])
  end
end
