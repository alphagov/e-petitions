class PetitionsController < ApplicationController
  before_filter :assign_departments, :only => [:new, :create]
  before_filter :sanitise_page_param
  caches_action_with_params :index

  caches_page :show

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
    @petition = Petition.new(petition_attributes_for_create)
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
        @petition.errors[:action].any? ||
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

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver_now
  end

  def petition_attributes_for_create
   attributes = petition_params_for_create
   attributes[:sponsor_emails] = parse_emails(attributes[:sponsor_emails])
   attributes
  end

  def petition_params_for_create
    params.
      require(:petition).
      permit(:title, :action, :description, :duration, :department_id,
             :sponsor_emails,
             creator_signature_attributes: [
               :name, :email, :email_confirmation, :address, :town,
               :postcode, :country, :uk_citizenship,
               :terms_and_conditions, :notify_by_email
             ])
  end
end

