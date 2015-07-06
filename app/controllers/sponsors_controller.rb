class SponsorsController < ApplicationController
  include ManagingMoveParameter

  before_action :retrieve_petition
  before_action :redirect_to_petition_url, if: :moderated?
  before_action :redirect_to_moderation_info_url, if: :has_maximum_sponsors?
  before_action :validate_creator_signature, only: %i[show]
  before_action :do_not_cache

  respond_to :html

  def show
    assign_stage
    @sponsor = @petition.sponsors.build
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, @petition, params[:stage], params[:move])
  end

  def update
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, @petition, params[:stage], params[:move])
    if @stage_manager.create_signature
      @signature = @stage_manager.signature
      @signature.store_constituency_id
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
    @petition = Petition.not_hidden.find_by!(sponsor_token_and_id)
  end

  def sponsor_token_and_id
    { sponsor_token: params[:token].to_s, id: params[:petition_id].to_i }
  end

  def redirect_to_petition_url
    redirect_to petition_url(@petition)
  end

  def redirect_to_moderation_info_url
    redirect_to moderation_info_petition_url(@petition)
  end

  def moderated?
    @petition.moderated?
  end

  def has_maximum_sponsors?
    @petition.has_maximum_sponsors?
  end

  def validate_creator_signature
    @petition.validate_creator_signature!
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
    SponsorMailer.petition_and_email_confirmation_for_sponsor(sponsor).deliver_later
  end
end
