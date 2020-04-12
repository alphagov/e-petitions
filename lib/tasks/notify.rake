require "notifications/client"
require "fileutils"

namespace :notify do
  task fetch_templates: :environment do
    template_dir = Rails.root.join("spec", "fixtures", "notify")
    client = Notifications::Client.new(ENV.fetch("NOTIFY_API_KEY"))
    templates = client.get_all_templates(type: "email")

    FileUtils.rm_rf template_dir
    FileUtils.mkdir_p template_dir

    templates.collection.each do |template|
      template_path = template_dir.join("#{template.id}.yml")

      yaml = <<~YAML
        id: "#{template.id}"
        name: "#{template.name}"
        subject: "#{template.subject}"
        body: |-
        #{template.body.split("\r\n").map { |l| "  #{l}" }.join("\n")}
      YAML

      File.write(template_path, yaml)
    end
  rescue Notifications::Client::RequestError => e
    puts e.message
  end
end
