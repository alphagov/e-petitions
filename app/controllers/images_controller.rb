class ImagesController < ActiveStorage::Representations::ProxyController
  def admin_request?
    false
  end

  private
    # TODO: Remove this when Rails 6.1.4 is released
    # Reference: https://github.com/rails/rails/issues/41772
    def set_representation
      @representation = @blob.representation(params[:variation_key]).processed
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      head :not_found
    end
end
