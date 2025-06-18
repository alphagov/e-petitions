class ConstituenciesController < PublicController
  before_action :set_cors_headers, only: [:index], if: :json_request?
  before_action :fetch_parliament, only: [:index]
  before_action :fetch_constituencies, only: [:index]

  def index
    expires_in 1.hour, public: true,
      stale_while_revalidate: 60.seconds,
      stale_if_error: 5.minutes

    respond_to do |format|
      format.json
    end
  end

  private

  def fetch_parliament
    case params[:period]
    when Parliament::PERIOD_FORMAT
      @parliament = Parliament.archived.find_by!(period: params[:period])
    else
      @parliament = Parliament.instance
    end
  end

  def fetch_constituencies
    @constituencies = @parliament.constituencies.by_ons_code
  end
end
