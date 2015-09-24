require 'webrick/https'
require 'rack/handler/webrick'

module Epets
  class SSLServer
    class << self
      def build(app, port)
        Rack::Handler::WEBrick.run(app, defaults.merge(Port: port))
      end

      private

      def defaults
        {
          SSLEnable:       true,
          SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
          SSLPrivateKey:   private_key,
          SSLCertificate:  ssl_certificate,
          SSLCertName:     [["US", 'localhost']],
          AccessLog:       [],
          Logger:          logger
        }
      end

      def logger
        WEBrick::Log::new(log_path)
      end

      def log_path
        Rails.root.join("./log/capybara_test.log").to_s
      end

      def private_key
        OpenSSL::PKey::RSA.new(File.read(private_key_path))
      end

      def private_key_path
        Rails.root.join("./spec/support/server.key").to_s
      end

      def ssl_certificate
        OpenSSL::X509::Certificate.new(File.read(ssl_certificate_path))
      end

      def ssl_certificate_path
        Rails.root.join("./spec/support/server.crt").to_s
      end
    end
  end
end

# See the following urls for context on this monkey patch:
# http://cowjumpedoverthecommodore64.blogspot.co.uk/2013/09/if-your-website-runs-under-ssl-than.html
# https://github.com/jnicklas/capybara/issues/1121
module Capybara
  class Server
    def responsive?
      return false if @server_thread && @server_thread.join(0)

      http = Net::HTTP.new(host, @port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.get('/__identify__')

      if res.is_a?(Net::HTTPSuccess) or res.is_a?(Net::HTTPRedirection)
        return res.body == @app.object_id.to_s
      end
    rescue SystemCallError
      return false
    end
  end
end
