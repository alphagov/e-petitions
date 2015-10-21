class Admin::SignaturesController < Admin::AdminController
  before_action :fetch_signature

  def validate
    begin
      @signature.validate!
      redirect_to admin_search_url(q: @signature.email), notice: "Signature validated successfully"
    rescue StandardError => e
      Appsignal.send_exception e
      redirect_to admin_search_url(q: @signature.email), alert: "Signature could not be validated - please contact support"
    end
  end

  def destroy
    if @signature.destroy
      redirect_to admin_search_url(q: @signature.email), notice: "Signature removed successfully"
    else
      redirect_to admin_search_url(q: @signature.email), alert: "Signature could not be removed - please contact support"
    end
  end

  private

  def fetch_signature
    @signature = Signature.find(params[:id])
  end
end
