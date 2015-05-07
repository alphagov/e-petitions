class SponsorsController < ApplicationController
  before_action :retrieve_petition
  before_action :retrieve_sponsor

  respond_to :html

  def show
    @signature = @sponsor.build_signature(:country => "United Kingdom")
  end

  private
  def retrieve_petition
    # TODO: scope the petitions we look at?
    @petition = Petition.find(params[:petition_id])
  end

  def retrieve_sponsor
    @sponsor = @petition.sponsors.find_by!(perishable_token: params[:token])
  end
end
