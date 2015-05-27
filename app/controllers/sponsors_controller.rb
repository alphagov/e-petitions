class SponsorsController < ApplicationController
  before_action :retrieve_petition
  before_action :retrieve_sponsor

  respond_to :html

  def show
    if @sponsor.signature.nil?
      assign_stage
      @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, @petition, params[:stage], params[:move])
    else
      redirect_to thank_you_petition_sponsor_url(@petition, token: @sponsor.perishable_token)
    end
  end

  def update
    if @sponsor.signature.nil?
      assign_stage
      @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, @petition, params[:stage], params[:move])
      if @stage_manager.create_signature
        @signature = @stage_manager.signature
        @sponsor.update_attribute(:signature, @signature)
        # If the user has filled in all the correc things then we can
        # go straight to validated without the email: the sponsor email
        # that gets them here acts as a validation of their email address
        @signature.perishable_token = nil
        @signature.state = Signature::VALIDATED_STATE
        @signature.save(:validate => false)
        send_sponsor_support_notificaiton_email_to_petition_owner(@petition, @sponsor)
        @petition.update_sponsored_state
        redirect_to thank_you_petition_sponsor_url(@petition, token: @sponsor.perishable_token)
      else
        render :show
      end
    else
      redirect_to thank_you_petition_sponsor_url(@petition, token: @sponsor.perishable_token)
    end
  end

  def thank_you
    unless @sponsor.signature.present?
      redirect_to petition_sponsor_url(@petition, token: @sponsor.perishable_token)
    end
  end

  private
  def retrieve_petition
    # TODO: scope the petitions we look at?
    @petition = Petition.find(params[:petition_id])
  end

  def retrieve_sponsor
    @sponsor = @petition.sponsors.find_by!(perishable_token: params[:token])
  end

  def assign_stage
    return if Staged::PetitionSigner.stages.include? params[:stage]
    params[:stage] = 'signer'
  end

  def signature_params_for_new
    {country: 'United Kingdom', email: @sponsor.email}
  end

  def signature_params_for_create
    params.
      require(:signature).
      permit(:name, :email, :postcode, :country, :uk_citizenship)
  end

  def send_sponsor_support_notificaiton_email_to_petition_owner(petition, sponsor)
    petition.notify_creator_about_sponsor_support(sponsor)
  end
end
