class SponsorsController < ApplicationController
  include ManagingMoveParameter

  before_action :retrieve_petition
  before_action :redirect_to_petition_url, if: :moderated?, except: [:sponsored, :thank_you]
  before_action :redirect_to_moderation_info_url, if: :has_maximum_sponsors?, except: [:sponsored, :thank_you]
  before_action :validate_creator_signature, only: %i[show]
  before_action :do_not_cache

  respond_to :html

  def show
    assign_stage
    @sponsor = @petition.sponsors.build
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, request, @petition, params[:stage], params[:move])
    respond_with @sponsor
  end

  def update
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, request, @petition, params[:stage], params[:move])
    if @stage_manager.create_signature
      @signature = @stage_manager.signature
      @signature.store_constituency_id
      @sponsor = @petition.sponsors.create(signature: @signature)
      send_email_to_sponsor(@sponsor)
      redirect_to thank_you_petition_sponsor_url(@petition, token: @petition.sponsor_token)
    else
      respond_to do |format|
        format.html { render :show }
      end
    end
  rescue ActiveRecord::RecordNotUnique => e
    redirect_to thank_you_petition_sponsor_url(@petition, token: @petition.sponsor_token)
  end

  def thank_you
    respond_to do |format|
      format.html
    end
  end

  def sponsored
    respond_to do |format|
      format.html
    end
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
    {location_code: 'GB'}
  end

  def signature_params_for_create
    params.
      require(:signature).
      permit(:name, :email, :postcode, :location_code, :uk_citizenship)
  end

  def send_email_to_sponsor(sponsor)
    PetitionAndEmailConfirmationForSponsorEmailJob.perform_later(sponsor)
  end
end
