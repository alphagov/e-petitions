require 'action_controller/metal/exceptions'

class RejectBadRequests
  NULL_BYTE = "\u0000".freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      params = Rack::Request.new(env).params
    rescue StandardError
      raise ActionController::BadRequest, 'Request is invalid or has been corrupted'
    end

    if bad_request?(params)
      raise ActionController::BadRequest, 'Parameters contain invalid characters'
    else
      @app.call(env)
    end
  end

  private

    def bad_request?(params)
      case params
      when Hash
        params.any? { |_, param| bad_request?(param) }
      when Array
        params.any? { |param| bad_request?(param) }
      when String
        params.include?(NULL_BYTE)
      when Tempfile
        false # uploaded files may contain null bytes
      else
        raise ActionController::BadRequest, "Parameters contains unexpected type: #{params.class.name}"
      end
    end
end
