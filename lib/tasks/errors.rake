namespace :errors do
  desc "Precompile error pages into /public"
  task :precompile => :environment do
    require 'base64'

    load_path = Rails.root.join("app/assets/stylesheets")
    build_path = Rails.root.join("app/assets/builds")

    args = %W[
      #{load_path.join("error.scss")}:#{build_path.join("error.css")}
    ]

    args.concat %w[--quiet --quiet-deps]
    args.concat %w[--pkg-importer node]
    args.concat %w[--style compressed]
    args.concat %w[--no-source-map]

    begin
      system("bin/sass", *args, exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end

    begin
      system("node esbuild.mjs --error --minify", exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end

    css_file = Rails.application.assets.load_path.find("error.css")
    js_file = Rails.application.assets.load_path.find("error.js")
    output_path = Rails.public_path.join("assets")
    FileUtils.mkdir_p(output_path)

    File.open(output_path.join(css_file.digested_path), "w+") do |file|
      begin
        file.write css_file.compiled_content
      rescue Encoding::UndefinedConversionError
        file.write css_file.compiled_content.force_encoding("UTF-8")
      end
    end

    File.open(output_path.join(js_file.digested_path), "w+") do |file|
      begin
        file.write js_file.compiled_content
      rescue Encoding::UndefinedConversionError
        file.write js_file.compiled_content.force_encoding("UTF-8")
      end
    end

    controller_class = Class.new(ActionController::Base) do
      def url_options
        Site.constraints_for_public
      end
    end

    context_class = Class.new(ActionView::Base.with_empty_template_cache) do
      include Rails.application.routes.url_helpers

      def asset_url(path)
        Rails.application.assets.load_path.find(path).digested_path
      end

      def home_page?
        false
      end

      def navigation_item(name, page)
        %[<li><a href="#{page}">#{name}</a></li>].html_safe
      end
    end

    lookup_context = ActionView::LookupContext.new('app/views')

    ActionView::Base.annotate_rendered_view_with_filenames = false

    errors_path = Rails.public_path.join("errors")
    FileUtils.mkdir_p(errors_path)

    %w[400 403 404 406 410 422 500 503].each do |status|
      context = context_class.new(lookup_context, { status: status }, controller_class.new)
      File.open(errors_path.join("#{status}.html"), 'wb') do |f|
        f.write context.render(template: "errors/#{status}", layout: 'errors/layout')
      end
    end
  end

  task :clobber => :environment do
    errors_path = Rails.public_path.join("errors")
    FileUtils.rm_rf(errors_path)

    output_path = Rails.public_path.join("assets")

    css_file = Rails.application.assets.load_path.find('error.css')
    js_file = Rails.application.assets.load_path.find('error.js')

    css_path = output_path.join(css_file.digested_path)
    js_path = output_path.join(js_file.digested_path)

    File.unlink(css_path) if File.exist?(css_path)
    File.unlink(js_path) if File.exist?(js_path)
    FileUtils.rmdir(output_path) if Dir.empty?(output_path)
  end
end

task 'assets:precompile' => 'errors:precompile'
task 'assets:clobber' => 'errors:clobber'
