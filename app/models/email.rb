module Email
  class << self
    def table_name_prefix
      "email_"
    end

    def dump!
      dump_partials!
      dump_templates!
    end

    def dump_partials!
      File.write(partials_file, dump_partials)
    end

    def dump_partials
      Email::Partial.by_name.map(&:dump).to_h.to_yaml(line_width: -1)
    end

    def dump_templates!
      File.write(templates_file, dump_templates)
    end

    def dump_templates
      Email::Template.mailer_names.map do |name|
        [name, Email::Template.for_mailer(name).map(&:dump).to_h]
      end.to_h.to_yaml(line_width: -1)
    end

    def load!
      load_partials!
      load_templates!
    end

    def load_partials!
      load_partials(YAML.load_file(partials_file))
    end

    def load_partials(partials)
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

    def load_templates!
      load_templates(YAML.load_file(templates_file))
    end

    def load_templates(templates)
      templates.each do |mailer_name, action_names|
        action_names.each do |action_name, attributes|
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

    private

    def partials_file
      Rails.root.join("config", "email", "partials.yml")
    end

    def templates_file
      Rails.root.join("config", "email", "templates.yml")
    end
  end
end
