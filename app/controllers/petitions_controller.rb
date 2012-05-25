class PetitionsController < ApplicationController
  before_filter :assign_departments, :only => [:new, :create]
  before_filter :sanitise_page_param
  caches_action_with_params :index

  caches_page :show

  ssl_required :new, :create
  ssl_allowed :thank_you

  respond_to :html

  include SearchResultsSetup

  def index
    results_for(Petition)
  end

  def new
    @petition = Petition.new(:title => params[:title])
    @petition.build_creator_signature(:country => 'United Kingdom')
    @start_on_section = 0;
    respond_with @petition
  end

  def show
    respond_with @petition = Petition.visible.find(params[:id])
  end

  def create
    params[:petition][:creator_signature_attributes][:humanity] = Captcha.verify(params[:captcha_response_field], params[:captcha_string])

    @petition = Petition.new(params[:petition])
    @petition.creator_signature.email.strip!
    if @petition.creator_signature
      @petition.creator_signature.ip_address = request.remote_ip
      @petition.creator_signature.notify_by_email = true
    end

    @petition.title.strip!
    if @petition.save
      send_email_to_verify_petition_creator(@petition)
      redirect_to thank_you_petition_path(@petition, :secure => true)
    else
      if @petition.errors[:title].any? ||
        @petition.errors[:department].any? ||
        @petition.errors[:description].any?
        @start_on_section = 0
      elsif @petition.creator_signature.errors[:name].any? ||
        @petition.creator_signature.errors[:email].any? ||
        @petition.creator_signature.errors[:uk_citizenship].any? ||
        @petition.creator_signature.errors[:address].any? ||
        @petition.creator_signature.errors[:town].any? ||
        @petition.creator_signature.errors[:postcode].any? ||
        @petition.creator_signature.errors[:country].any?
        @start_on_section = 1
      elsif @petition.creator_signature.errors[:humanity].any?
        @start_on_section = 2
      else
        @start_on_section = 0
      end
      render :new
    end
  end

  def check
  end

  def check_results
    @petition_search = PetitionResults.new(
      :search_term    => params[:search],
      :state => params[:state],
      :per_page       => 10,
      :page_number    => params[:page],
      :sort           => params[:sort],
      :order          => params[:order]
    )
  end

  def resend_confirmation_email
    @petition = Petition.visible.find(params[:id])
    SignatureConfirmer.new(@petition, params[:confirmation_email], PetitionMailer, Authlogic::Regex.email).confirm!
  end

  protected

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver
  end
end
