require 'postcode_sanitizer'
require 'csv'

class LocalPetitionsController < LocalizedController
  before_action :sanitize_postcode, only: :index
  before_action :find_by_postcode, if: :postcode?, only: :index
  before_action :find_by_id, only: [:show, :all]
  before_action :find_member, only: [:show, :all]
  before_action :find_region, only: [:show, :all]
  before_action :find_regional_members, only: [:show, :all]
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

  def find_by_id
    @constituency = Constituency.find(params[:id])
  end

  def find_member
    @member = @constituency.member
  end

  def find_region
    @region = @constituency.region
  end

  def find_regional_members
    @members = @region.members
  end

  def constituency?
    @constituency.present?
  end

  def find_petitions
    @petitions = Petition.popular_in_constituency(@constituency.id, 50)
  end

  def find_all_petitions
    @petitions = Petition.all_popular_in_constituency(@constituency.id, 50)
  end

  def redirect_to_constituency
    redirect_to local_petition_url(@constituency.id)
  end

  def csv_filename
    if action_name == 'all'
      I18n.t :"local_petitions.csv_filename.all", constituency: @constituency.slug
    else
      I18n.t :"local_petitions.csv_filename.open", constituency: @constituency.slug
    end
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
