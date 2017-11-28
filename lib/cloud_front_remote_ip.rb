require 'action_dispatch/middleware/remote_ip'

class CloudFrontRemoteIp < ActionDispatch::RemoteIp
  HTTP_X_AMZ_CF_ID = 'HTTP_X_AMZ_CF_ID'.freeze
  REMOTE_IP = 'action_dispatch.remote_ip'.freeze

  def call(env)
    req = ActionDispatch::Request.new env
    req.remote_ip = CloudFrontGetIp.new(req, check_ip, proxies)
    @app.call(req.env)
  end

  class CloudFrontGetIp < GetIp
    protected

    def filter_proxies(ips)
      # If the request is coming from CloudFront we
      # can safely remove the rightmost ip address
      # filtering out the VPC ip address
      if @req.has_header?(HTTP_X_AMZ_CF_ID)
        super(ips)[1..-1]
      else
        super(ips)
      end
    end
  end
end
