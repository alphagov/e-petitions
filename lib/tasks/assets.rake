namespace :css do
  load_path = Rails.root.join("app/assets/stylesheets")
  build_path = Rails.root.join("app/assets/builds")

  args = %W[
    #{load_path.join("admin.scss")}:#{build_path.join("admin.css")}
    #{load_path.join("application.scss")}:#{build_path.join("application.css")}
    #{load_path.join("delayed/web/application.scss")}:#{build_path.join("delayed/web/application.css")}
  ]

  Rails.application.config.assets.paths.each do |path|
    next unless path.include?("stylesheets")
    args.concat ["--load-path", path.to_s]
  end

  args.concat %w[--quiet --quiet-deps]

  desc "Build your Sass CSS bundle"
  task build: :environment do
    begin
      system("bin/sass", *args, exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end

  desc "Watch and build your Sass CSS bundle on file changes"
  task watch: :environment do
    extra_args = %w[
      --watch
    ]

    begin
      system("bin/sass", *args, *extra_args, exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end

  task precompile: :environment do
    extra_args = %w[
      --style compressed
      --no-source-map
    ]

    begin
      system("bin/sass", *args, *extra_args, exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end
end

unless ENV["SKIP_CSS_BUILD"]
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance(["css:precompile"])
  end

  if Rake::Task.task_defined?("test:prepare")
    Rake::Task["test:prepare"].enhance(["css:build"])
  elsif Rake::Task.task_defined?("db:test:prepare")
    Rake::Task["db:test:prepare"].enhance(["css:build"])
  end
end

namespace :javascript do
  desc "Build your JavaScript bundle"
  task build: :environment do
    begin
      system("node esbuild.mjs", exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end

  desc "Watch and build your JavaScript bundle on file changes"
  task watch: :environment do
    begin
      system("node esbuild.mjs --watch", exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end

  task precompile: :environment do
    begin
      system("node esbuild.mjs --minify", exception: true)
    rescue Interrupt
      abort("Exiting ...")
    end
  end
end

unless ENV["SKIP_JS_BUILD"]
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance(["javascript:precompile"])
  end

  if Rake::Task.task_defined?("test:prepare")
    Rake::Task["test:prepare"].enhance(["javascript:build"])
  elsif Rake::Task.task_defined?("db:test:prepare")
    Rake::Task["db:test:prepare"].enhance(["javascript:build"])
  end
end
