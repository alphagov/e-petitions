class SponsorsController < ApplicationController
  before_action :retrieve_petition

  respond_to :html

  def show
    if @petition.sponsor_token == params[:token]
      assign_stage
      @sponsor = @petition.sponsors.build
      @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, @petition, params[:stage], params[:move])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def update
    if @petition.sponsor_token == params[:token]
      assign_stage
      @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, @petition, params[:stage], params[:move])
      if @stage_manager.create_signature
        @signature = @stage_manager.signature
        @sponsor = @petition.sponsors.create(signature: @signature)
        send_email_to_sponsor(@sponsor)
        redirect_to thank_you_petition_sponsor_url(@petition, token: @petition.sponsor_token)
      else
        render :show
      end
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def thank_you
    raise ActiveRecord::RecordNotFound unless @petition.sponsor_token == params[:token]
  end

  def sponsored
    raise ActiveRecord::RecordNotFound unless @petition.sponsor_token == params[:token]
  end

  private
  def retrieve_petition
    # TODO: scope the petitions we look at?
    @petition = Petition.find(params[:petition_id])
  end

  def assign_stage
    return if Staged::PetitionSigner.stages.include? params[:stage]
    params[:stage] = 'signer'
  end

  def signature_params_for_new
    {country: 'United Kingdom'}
  end

  def signature_params_for_create
    params.
      require(:signature).
      permit(:name, :email, :postcode, :country, :uk_citizenship)
  end

  def send_email_to_sponsor(sponsor)
    SponsorMailer.petition_and_email_confirmation_for_sponsor(sponsor).deliver_now
  end
end
