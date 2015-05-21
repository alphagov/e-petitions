class SignaturesController < ApplicationController
  before_filter :retrieve_petition, :only => [:new, :create, :thank_you, :signed]
  include ActionView::Helpers::NumberHelper

  respond_to :html

  def new
    @signature = Signature.new(:petition => @petition, :country => "United Kingdom")
  end

  def create
    @signature = Signature.new(signature_params_for_create)
    @signature.email.strip!
    @signature.petition = @petition

    matching_signatures = Signature.pending.matching(@signature)
    if matching_signatures.any?
      handle_existing_signatures(matching_signatures, @petition)
    else
      handle_new_signature(@signature, @petition)
    end
  end

  def verify
    @signature = Signature.find(params[:id])

    if @signature.perishable_token == params[:token]
      @signature.perishable_token = nil
      @signature.state = Signature::VALIDATED_STATE
      @signature.save(:validate => false)    #WHY SKIPPING VALIDATIONS??

      # if signature is that of the petition's creator, mark the petition as validated
      if @signature.petition.creator_signature == @signature
        @signature.petition.state = Petition::VALIDATED_STATE
        @signature.petition.notify_sponsors
        @signature.petition.save!

    # else signature is from an ordinary signee so let's redirect to petition's page
      else
        redirect_to signed_petition_signature_path(@signature.petition) and return
      end
    else
      # We've found the signature, but it's already been verified.
      if @signature.state == Signature::VALIDATED_STATE
        flash[:notice] = "Thank you. Your signature has already been added to the <span class='nowrap'>e-petition</span>.".html_safe
        redirect_to signed_petition_signature_path(@signature.petition) and return
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  private
  def retrieve_petition
    @petition = Petition.visible.find(params[:petition_id])
  end

  def send_email_to_petition_signer(signature)
    PetitionMailer.email_confirmation_for_signer(signature).deliver_now
  end

  def signature_params_for_create
    params.
      require(:signature).
      permit(:name, :email, :email_confirmation,
             :postcode, :country, :uk_citizenship)
  end

  def handle_existing_signatures(signatures, petition)
    signatures.each { |sig| send_email_to_petition_signer(sig) }
    redirect_to thank_you_petition_signature_path(petition)
  end

  def handle_new_signature(signature, petition)
    send_email_to_petition_signer(signature) if signature.save
    respond_with signature, :location => thank_you_petition_signature_path(petition)
  end
end
