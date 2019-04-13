require 'csv'

class Admin::LogsController < Admin::AdminController
  before_action :fetch_logs
  before_action :fetch_signature
  before_action :fetch_petition

  after_action :set_content_disposition, if: :csv_request?

  def show
    respond_to do |format|
      format.html
      format.csv
    end
  end

  private

  def fetch_logs
    @logs = SignatureLogs.find(params[:signature_id])
  end

  def fetch_signature
    @signature = @logs.signature
  end

  def fetch_petition
    @petition = @signature.petition
  end

  def csv_filename
    "signature-#{@signature.id}-access-logs.csv"
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
