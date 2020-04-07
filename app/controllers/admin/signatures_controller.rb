class Admin::SignaturesController < Admin::AdminController
  include BulkVerification

  before_action :fetch_petition, if: :petition_scope?
  before_action :fetch_signatures, only: [:index]
  before_action :fetch_signature, except: [:index, :new, :create, :bulk_validate, :bulk_invalidate, :bulk_subscribe, :bulk_unsubscribe, :bulk_destroy]
  before_action :build_signature, only: [:new, :create]

  helper_method :search_params

  def index
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @signature.save
      @signature.validate!(force: true)
      redirect_to admin_petition_url(@petition), notice: :signature_added
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def bulk_validate
    begin
      scope.validate!(selected_ids, force: true)
      redirect_to index_url(search_params), notice: :signatures_validated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signatures_not_validated
    end
  end

  def validate
    begin
      @signature.validate!(force: true)
      redirect_to index_url(search_params), notice: :signature_validated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signature_not_validated
    end
  end

  def bulk_invalidate
    begin
      scope.invalidate!(selected_ids)
      redirect_to index_url(search_params), notice: :signatures_invalidated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signatures_not_invalidated
    end
  end

  def invalidate
    begin
      @signature.invalidate!
      redirect_to index_url(search_params), notice: :signature_invalidated
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(q: @signature.email), alert: :signature_not_invalidated
    end
  end

  def bulk_destroy
    begin
      scope.destroy!(selected_ids)
      redirect_to index_url(search_params), notice: :signatures_deleted
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signatures_not_deleted
    end
  end

  def destroy
    if @signature.destroy
      redirect_to index_url(search_params), notice: :signature_deleted
    else
      redirect_to index_url(search_params), alert: :signature_not_deleted
    end
  end

  def bulk_subscribe
    begin
      scope.subscribe!(selected_ids)
      redirect_to index_url(search_params), notice: :signatures_subscribed
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signatures_not_subscribed
    end
  end

  def subscribe
    if @signature.update(notify_by_email: true)
      redirect_to admin_signatures_url(search_params), notice: :signature_subscribed
    else
      redirect_to admin_signatures_url(search_params), alert: :signature_not_subscribed
    end
  end

  def bulk_unsubscribe
    begin
      scope.unsubscribe!(selected_ids)
      redirect_to index_url(search_params), notice: :signatures_unsubscribed
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to index_url(search_params), alert: :signatures_not_unsubscribed
    end
  end

  def unsubscribe
    if @signature.update(notify_by_email: false)
      redirect_to index_url(search_params), notice: :signature_unsubscribed
    else
      redirect_to index_url(search_params), alert: :signature_not_unsubscribed
    end
  end

  private

  def petition_scope?
    params.key?(:petition_id)
  end

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def scope
    params.key?(:petition_id) ? @petition.signatures : Signature
  end

  def fetch_signatures
    @signatures = scope.search(params[:q], search_params)
  end

  def fetch_signature
    @signature = scope.find(params[:id])
  end

  def build_signature
    if action_name == "new"
      @signature = @petition.signatures.build(signature_params_for_new)
    else
      @signature = @petition.signatures.build(signature_params_for_create)
    end
  end

  def signature_params_for_new
    { location_code: "GB-WLS" }
  end

  def signature_params
    params.require(:signature).permit(*signature_attributes)
  end

  def signature_params_for_create
    signature_params.merge(ip_address: request.remote_ip)
  end

  def signature_attributes
    %i[name postcode location_code autogenerate_email]
  end

  def search_params
    params.permit(:q, :page, :state, :window).to_h
  end

  def index_url(*args)
    if petition_scope?
      admin_petition_signatures_url(*args)
    else
      admin_signatures_url(*args)
    end
  end
end
