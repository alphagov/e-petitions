class Admin::Archived::SignaturesController < Admin::AdminController
  include BulkVerification

  before_action :fetch_signature, except: [:index, :bulk_subscribe, :bulk_unsubscribe, :bulk_destroy]
  before_action :fetch_signatures, only: [:index]

  helper_method :search_params

  def index
    respond_to do |format|
      format.html
    end
  end

  def bulk_destroy
    begin
      ::Archived::Signature.destroy!(selected_ids)
      redirect_to admin_archived_signatures_url(search_params), notice: :signatures_deleted
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_archived_signatures_url(search_params), alert: :signatures_not_deleted
    end
  end

  def destroy
    if @signature.destroy
      redirect_to admin_archived_signatures_url(search_params), notice: :signature_deleted
    else
      redirect_to admin_archived_signatures_url(search_params), alert: :signature_not_deleted
    end
  end

  def bulk_subscribe
    begin
      ::Archived::Signature.subscribe!(selected_ids)
      redirect_to admin_archived_signatures_url(search_params), notice: :signatures_subscribed
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_archived_signatures_url(search_params), alert: :signatures_not_subscribed
    end
  end

  def subscribe
    if @signature.update(notify_by_email: true)
      redirect_to admin_archived_signatures_url(search_params), notice: :signature_subscribed
    else
      redirect_to admin_archived_signatures_url(search_params), alert: :signature_not_subscribed
    end
  end

  def bulk_unsubscribe
    begin
      ::Archived::Signature.unsubscribe!(selected_ids)
      redirect_to admin_archived_signatures_url(search_params), notice: :signatures_unsubscribed
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_archived_signatures_url(search_params), alert: :signatures_not_unsubscribed
    end
  end

  def unsubscribe
    if @signature.update(notify_by_email: false)
      redirect_to admin_archived_signatures_url(search_params), notice: :signature_unsubscribed
    else
      redirect_to admin_archived_signatures_url(search_params), alert: :signature_not_unsubscribed
    end
  end

  private

  def fetch_signatures
    @signatures = ::Archived::Signature.search(params[:q], search_params)
  end

  def fetch_signature
    @signature = ::Archived::Signature.find(params[:id])
  end

  def search_params
    params.slice(:q, :page, :state, :window)
  end
end
