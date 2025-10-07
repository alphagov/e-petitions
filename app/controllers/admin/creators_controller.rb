class Admin::CreatorsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_petition
  before_action :fetch_creator

  before_action unless: :hidden_or_removed? do
    redirect_to admin_petition_url(@petition), alert: :petition_not_hidden_or_removed
  end

  before_action if: :already_anonymized? do
    redirect_to admin_petition_url(@petition), alert: :creator_already_anonymized
  end

  rescue_from ActiveRecord::ActiveRecordError do
    redirect_to admin_petition_url(@petition), alert: :creator_not_anonymized
  end

  def destroy
    @creator.anonymize!(Time.current)

    respond_to do |format|
      format.html { redirect_to admin_petition_url(@petition), notice: :creator_anonymized }
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def fetch_creator
    @creator = @petition.creator
  end

  def hidden_or_removed?
    @petition.hidden? || @petition.removed?
  end

  def already_anonymized?
    @creator.anonymized?
  end
end
