namespace :errors do
  desc "Precompile error pages into /public"
  task :precompile => :environment do
    require 'base64'

    controller_class = Class.new(ActionController::Base) do
      def url_options
        Site.constraints_for_public
      end
    end

    context_class = Class.new(ActionView::Base.with_empty_template_cache) do
      include Rails.application.routes.url_helpers

      def data_uri(path)
        "data:image/png;base64,#{Base64.strict_encode64(asset_data(path))}"
      end

      def asset_data(path)
        File.read(Rails.root.join('app', 'assets', 'images', path))
      end

      def home_page?
        false
      end
    end

    lookup_context = ActionView::LookupContext.new('app/views')

    %w[400 403 404 406 422 500 503].each do |status|
      context = context_class.new(lookup_context, { status: status }, controller_class.new)
      File.open(Rails.public_path.join("#{status}.html"), 'wb') do |f|
        f.write context.render(template: "errors/#{status}", layout: 'errors/layout')
      end
    end

    context = context_class.new(lookup_context, {}, controller_class.new)
    File.open(Rails.public_path.join("error.css"), 'wb') do |f|
      f.write context.render(template: "errors/error", layout: false)
    end
  end
end

task 'assets:precompile' => 'errors:precompile'
