module Email
  class << self
    def table_name_prefix
      "email_"
    end

    def dump!
      File.write(locale_file, dump)
    end

    def load!
      load_partials
      load_templates
    end

    private

    def dump
      {
        "en-GB" => {
          "emails" => {
            "partials" => dump_partials,
            "templates" => dump_templates
          }
        }
      }.to_yaml
    end

    def locale_file
      Rails.root.join("config", "locales", "emails.en-GB.yml")
    end

    def dump_partials
      Email::Partial.by_name.map(&:dump).to_h
    end

    def dump_templates
      Email::Template.mailer_names.map do |name|
        [name, Email::Template.for_mailer(name).map(&:dump).to_h]
      end.to_h
    end

    def load_partials
      partials.each do |name, content|
        begin
          Email::Partial.for(name) do |partial|
            partial.update!(content: content)
          end
        rescue ActiveRecord::RecordNotUnique => e
          retry
        end
      end
    end

    def load_templates
      mailers.each do |mailer_name, templates|
        templates.each do |action_name, attributes|
          begin
            Email::Template.for(mailer_name, action_name) do |template|
              template.update!(attributes)
            end
          rescue ActiveRecord::RecordNotUnique => e
            retry
          end
        end
      end
    end

    def partials
      I18n.t!("emails.partials")
    end

    def mailers
      I18n.t!("emails.templates")
    end
  end
end
