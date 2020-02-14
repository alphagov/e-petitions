require 'fileutils'
require 'webrick/https'
require 'rack/handler/webrick'

module WelshPets
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
          SSLCertName:     [['GB', 'petition.senedd.wales']],
          AccessLog:       [],
          Logger:          logger
        }
      end

      def logger
        WEBrick::Log::new(log_path)
      end

      def log_path
        Rails.root.join('log', 'capybara_test.log').to_s
      end

      def private_key
        unless File.exist?(private_key_path)
          generate_ssl_certificate
        end

        OpenSSL::PKey::RSA.new(File.read(private_key_path))
      end

      def private_key_path
        ssl_dir.join('key.pem').to_s
      end

      def ssl_certificate
        unless File.exist?(ssl_certificate_path)
          generate_ssl_certificate
        end

        OpenSSL::X509::Certificate.new(File.read(ssl_certificate_path))
      end

      def ssl_certificate_path
        ssl_dir.join('cert.pem').to_s
      end

      def generate_ssl_certificate
        FileUtils.mkdir_p(ssl_dir) unless Dir.exist?(ssl_dir)

        details = []
        details << 'C=GB'
        details << 'ST=Wales'
        details << 'L=Cardiff'
        details << 'O=Welsh Parliament'
        details << 'OU=ICT'
        details << 'CN=petition.senedd.wales'

        args = %w[openssl req -x509]
        args.concat ['-newkey', 'rsa:2048']
        args.concat ['-keyout', private_key_path]
        args.concat ['-out', ssl_certificate_path]
        args.concat ['-days', '3650']
        args.concat ['-nodes', '-sha256']
        args.concat ['-subj', "/#{details.join('/')}"]

        Kernel.system *args, err: File::NULL, out: File::NULL
      end

      def ssl_dir
        Rails.root.join('tmp', 'ssl')
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
