class LoginController < PublicController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate

  before_action :redirect_to_home_page_unless_site_protected
  before_action :redirect_to_home_page_if_authenticated, except: :destroy
  before_action :build_form, except: :destroy

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
      if @login.save
        cookies[:login] = Site.login_digest

        format.html do
          redirect_to home_url
        end
      else
        format.html { render :new }
      end
    end
  end

  def destroy
    cookies.delete(:login)

    respond_to do |format|
      format.html do
        redirect_to login_url
      end
    end
  end

  private

  def build_form
    @login = LoginForm.new(params, request)
  end

  def redirect_to_home_page_unless_site_protected
    redirect_to home_url unless Site.protected?
  end

  def redirect_to_home_page_if_authenticated
    redirect_to home_url if authenticated?
  end

  def login_cookie
    { value: login_digest, expires: Date.tomorrow.beginning_of_day, same_site: :strict }
  end
end
