module FormTracking
  extend ActiveSupport::Concern

  private

  def generate_form_token
    Authlogic::Random.friendly_token
  end

  def build_form_request
    { "form_token" => generate_form_token, "form_requested_at" => current_time }
  end

  def form_request_id
    petition_id.to_s
  end

  def form_requests
    session["form_requests"] ||= {}
    session["form_requests"]
  end

  def form_request
    form_requests[form_request_id] ||= build_form_request
    form_requests[form_request_id]
  end

  def form_token
    form_request["form_token"]
  end

  def form_requested_at
    form_request["form_requested_at"]
  end

  def image_loaded_at
    cookies.encrypted[form_token]
  end
end
