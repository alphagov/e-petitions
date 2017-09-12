require 'postcode_sanitizer'
require 'csv'

class LocalPetitionsController < ApplicationController
  before_action :sanitize_postcode, only: :index
  before_action :find_by_postcode, if: :postcode?, only: :index
  before_action :find_by_slug, only: [:show, :all]
  before_action :find_petitions, if: :constituency?, only: :show
  before_action :find_all_petitions, if: :constituency?, only: :all
  before_action :redirect_to_constituency, if: :constituency?, only: :index

  after_action :set_content_disposition, if: :csv_request?, only: [:show, :all]

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json
      format.csv
    end
  end

  def all
    respond_to do |format|
      format.html
      format.json
      format.csv
    end
  end

  private

  def sanitize_postcode
    @postcode = PostcodeSanitizer.call(params[:postcode])
  end

  def postcode?
    @postcode.present?
  end

  def find_by_postcode
    @constituency = Constituency.find_by_postcode(@postcode)
  end

  def find_by_slug
    @constituency = Constituency.find_by_slug!(params[:id])
  end

  def constituency?
    @constituency.present?
  end

  def find_petitions
    @petitions = Petition.popular_in_constituency(@constituency.external_id, 50)
  end

  def find_all_petitions
    @petitions = Petition.all_popular_in_constituency(@constituency.external_id, 50)
  end

  def redirect_to_constituency
    if Parliament.dissolved?
      redirect_to all_local_petition_url(@constituency.slug)
    else
      redirect_to local_petition_url(@constituency.slug)
    end
  end

  def csv_filename
    if action_name == 'all'
      "all-popular-petitions-in-#{@constituency.slug}.csv"
    else
      "open-popular-petitions-in-#{@constituency.slug}.csv"
    end
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
