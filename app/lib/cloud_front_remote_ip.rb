class CloudFrontRemoteIp < ActionDispatch::RemoteIp
  HTTP_X_AMZ_CF_ID = 'HTTP_X_AMZ_CF_ID'.freeze
  REMOTE_IP = 'action_dispatch.remote_ip'.freeze

  def call(env)
    env[REMOTE_IP] = CloudFrontGetIp.new(env, self)
    @app.call(env)
  end

  class CloudFrontGetIp < GetIp
    protected

    def filter_proxies(ips)
      # If the request is coming from CloudFront we
      # can safely remove the rightmost ip address
      # filtering out the VPC ip address
      if @env.key?(HTTP_X_AMZ_CF_ID)
        super(ips)[0..-2]
      else
        super(ips)
      end
    end
  end
end
