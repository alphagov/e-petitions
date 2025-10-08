class ParliamentsController < PublicController
  before_action :set_cors_headers, if: :json_request?
  before_action :fetch_parliaments, only: [:index]
  before_action :fetch_parliament, only: [:show]
  before_action :fetch_constituencies, only: [:show]

  def index
    expires_in 1.hour, public: true,
      stale_while_revalidate: 60.seconds,
      stale_if_error: 5.minutes

    respond_to do |format|
      format.json
    end
  end

  def show
    expires_in 1.hour, public: true,
      stale_while_revalidate: 60.seconds,
      stale_if_error: 5.minutes

    respond_to do |format|
     format.json
    end
  end

  private

  def fetch_parliaments
    @parliaments = Parliament.archived.order(:period)
  end

  def fetch_parliament
    @parliament = Parliament.archived.find_by!(period: params[:period])
  end

  def fetch_constituencies
    @constituencies = @parliament.constituencies.by_ons_code
  end
end
