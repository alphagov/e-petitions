module NotifyMock
  URL = "https://api.notifications.service.gov.uk/v2/notifications/email"

  APPLICATION = Module.new do
    class << self
      include MarkdownHelper

      def call(env)
        params = JSON.parse(env["rack.input"].read)
        template = templates.fetch(params["template_id"])

        message = Mail::Message.new
        subject = template["subject"].dup
        body    = template["body"].dup

        params["personalisation"].each do |key, value|
          subject.gsub!("((#{key}))", value.to_s)
          body.gsub!("((#{key}))", value.to_s)
        end

        text_part = markdown_to_text(body)
        html_part = markdown_to_html(body)

        message.message_id = "#{SecureRandom.uuid}@#{Site.host}"
        message.from = Site.email_from
        message.to = params["email_address"]
        message.subject = subject
        message.text_part = text_part
        message.html_part = html_part

        ActionMailer::Base.deliveries << message

        [ 200, { "Content-Type" => "application/json" }, ["{}"] ]
      end

      private

      def templates
        @templates ||= load_templates
      end

      def load_templates
        template_files.each_with_object({}) do |file, hash|
          hash[File.basename(file, ".yml")] = YAML.load_file(file)
        end
      end

      def template_files
        Dir["#{template_dir}/*.yml"]
      end

      def template_dir
        Rails.root.join("spec", "fixtures", "notify")
      end
    end
  end

  class << self
    def url
      URL
    end

    def app
      APPLICATION
    end
  end
end
