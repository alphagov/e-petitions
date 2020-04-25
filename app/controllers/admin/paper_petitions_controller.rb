class Admin::PaperPetitionsController < Admin::AdminController
  before_action :build_petition

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @paper_petition.save
      redirect_to admin_petition_url(@paper_petition.petition), notice: :submitted_paper_petition
    else
      respond_to do |format|
        format.html { render :new, alert: :unable_to_submit_paper_petition }
      end
    end
  end

  protected

  def petition_attributes
    %i[
      action_en action_cy
      background_en background_cy
      additional_details_en additional_details_cy
      signature_count locale submitted_on
      name email phone_number address postcode
    ]
  end

  def petition_params
    params.require(:paper_petition).permit(*petition_attributes)
  end

  def build_petition
    if action_name == "new"
      @paper_petition = PaperPetition.new
    else
      @paper_petition = PaperPetition.new(petition_params)
    end
  end
end
