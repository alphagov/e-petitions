class SponsorsController < ApplicationController
  include ManagingMoveParameter

  before_action :retrieve_petition
  before_action :validate_token_and_petition_match

  respond_to :html

  def show
    if @petition.hidden?
      raise ActiveRecord::RecordNotFound
    elsif @petition.rejected? || @petition.closed? || @petition.open?
      redirect_to petition_url(@petition)
    elsif @petition.has_maximum_sponsors?
      redirect_to moderation_info_petition_url(@petition)
    else
      assign_stage
      @sponsor = @petition.sponsors.build
      @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, @petition, params[:stage], params[:move])
    end
  end

  def update
    assign_move
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
  end

  def thank_you
  end

  def sponsored
  end

  private
  def retrieve_petition
    # TODO: scope the petitions we look at?
    @petition = Petition.find(params[:petition_id])
  end

  def validate_token_and_petition_match
    raise ActiveRecord::RecordNotFound unless @petition.sponsor_token == params[:token]
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
