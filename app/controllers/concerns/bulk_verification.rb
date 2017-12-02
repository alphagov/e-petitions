module BulkVerification
  extend ActiveSupport::Concern

  class InvalidBulkRequest < RuntimeError; end

  included do
    before_action :verify_bulk_request, if: :bulk_request?

    helper_method :bulk_verifier

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature do
      raise BulkVerification::InvalidBulkRequest, "Invalid bulk request for #{selected_ids.inspect}"
    end
  end

  private

  def bulk_request?
    action_name =~ /\Abulk_/
  end

  def bulk_verification_token
    session[:_bulk_verification_token] ||= SecureRandom.base64(32)
  end

  def bulk_verifier
    @_bulk_verifer ||= ActiveSupport::MessageVerifier.new(bulk_verification_token, serializer: JSON)
  end

  def selected_ids
    @_selected_ids ||= params[:selected_ids].to_s.split(",").map(&:to_i).reject(&:zero?).take(50)
  end

  def all_ids
    @_all_ids ||= bulk_verifier.verify(params[:all_ids])
  end

  def verify_bulk_request
    selected_ids.all?(&method(:verify_bulk_request_id))
  end

  def verify_bulk_request_id(id)
    all_ids.include?(id) || raise_bad_request(id)
  end

  def raise_bad_request(id)
    raise BulkVerification::InvalidBulkRequest, "Invalid bulk request - #{id} not present in #{all_ids.inspect}"
  end
end
