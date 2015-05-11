class SponsorsController < ApplicationController
  before_action :retrieve_petition
  before_action :retrieve_sponsor

  respond_to :html

  def show
    if @sponsor.signature.nil?
      @signature = @sponsor.build_signature(:country => "United Kingdom")
    else
      redirect_to thank_you_petition_sponsor_path(@petition, token: @sponsor.perishable_token, secure: true)
    end
  end

  def update
    if @sponsor.signature.nil?
      @signature = @sponsor.create_signature(signature_params_for_create)

      if @signature.persisted?
        # If the user has filled in all the correc things then we can
        # go straight to validated without the email: the sponsor email
        # that gets them here acts as a validation of their email address
        @signature.perishable_token = nil
        @signature.state = Signature::VALIDATED_STATE
        @signature.save(:validate => false)
        send_sponsor_support_notificaiton_email_to_petition_owner(@petition, @sponsor)
        redirect_to thank_you_petition_sponsor_path(@petition, token: @sponsor.perishable_token, secure: true)
      else
        render :show
      end
    else
      redirect_to thank_you_petition_sponsor_path(@petition, token: @sponsor.perishable_token, secure: true)
    end
  end

  def thank_you
    unless @sponsor.signature.present?
      redirect_to petition_sponsor_path(@petition, token: @sponsor.perishable_token, secure: true)
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

  def signature_params_for_create
    params.
      require(:signature).
      permit(:name, :address, :town,
             :postcode, :country, :uk_citizenship,
             :terms_and_conditions, :notify_by_email)
  end

  def send_sponsor_support_notificaiton_email_to_petition_owner(petition, sponsor)
    petition.notify_creator_about_sponsor_support(sponsor)
  end
end
