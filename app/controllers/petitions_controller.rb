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

  def show
    respond_with @petition = Petition.visible.find(params[:id])
  end

  def new
    assign_title
    @petition = StagedPetitionCreator.new(params, request)
    respond_with @petition
  end

  def create
    @petition = StagedPetitionCreator.new(params, request)

    if @petition.create
      send_email_to_verify_petition_creator(@petition)
      redirect_to thank_you_petition_path(@petition, :secure => true)
    else
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

  def assign_title
    return if params[:title].blank?
    title = params.delete(:title)
    params[:petition] ||= {}
    params[:petition][:title] = title
  end

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver_now
  end
end

