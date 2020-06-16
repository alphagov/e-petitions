require 'tmpdir'
require 'active_support/core_ext/string/strip'
require 'aws-sdk-codedeploy'
require 'aws-sdk-s3'
require 'faraday'
require 'erb'
require 'open3'

class PackageBuilder
  class << self
    def build!(environment = :preview)
      new(environment).build!
    end

    def deploy!(environment)
      new(environment).deploy!
    end
  end

  attr_reader :environment, :release, :revision, :tmpdir, :timestamp
  attr_reader :client, :completed

  def initialize(environment)
    @environment = environment.to_s
    @revision    = current_revision
    @tmpdir      = Dir.mktmpdir
    @timestamp   = Time.current.getutc
    @release     = @timestamp.strftime('%Y%m%d%H%M%S')
    @client      = nil
    @completed   = false
  end

  def build!
    info "Building to #{tmpdir}"

    create_archive
    extract_archive
    remove_archive
    write_appspec
    write_scripts

    Dir.chdir archive_path do
      package_gems unless skip_gems?
      create_revision_file
      remove_artifacts
    end

    build_package

    info "Built package #{package_name}"
  end

  def upload!
    s3 = Aws::S3::Resource.new(region: region, profile: profile)
    bucket = s3.bucket(release_bucket)
    release_obj = bucket.object(release_key)

    info "Uploading package #{package_name} to S3 ..."
    start_time = Time.current

    release_obj.upload_file(package_path)

    duration = Time.current - start_time
    info "Upload completed in #{duration} seconds."
  end

  def deploy!
    WebMock.allow_net_connect! if defined? WebMock

    if ci? && !deploy_build?
      info "Skipping deployment ..."
    else
      unless skip_build?
        build!
        upload!
      end

      create_deployments! if deploy_release?
    end
  end

  private

  def application_name
    "#{ENV.fetch('AWS_DEPLOYMENT_APP_NAME', 'wpets-app')}-#{environment}"
  end

  def archive_file
    File.join(tmpdir, "#{archive_name}.tar")
  end

  def archive_name
    'source'
  end

  def archive_path
    File.join(tmpdir, archive_name)
  end

  def build_package
    Dir.mkdir('pkg') unless Dir.exist?('pkg')

    args = %w[tar]
    args.concat ['-cz']
    args.concat ['-f', package_path]
    args.concat ['-C', tmpdir]
    args.concat ['.']

    info "Building package ..."
    Kernel.system(*args)
  end

  def ci?
    ENV.fetch('CI', 'false') == 'true'
  end

  def create_archive
    args = %w[git archive]
    args.concat ['--format', 'tar']
    args.concat ['--prefix', 'source/']
    args.concat ['--output', archive_file]
    args.concat [treeish]

    info "Creating archive ..."
    Kernel.system(*args)
  end

  def create_deployments!
    create_deployment!("Workers")
    create_deployment!("Counter")
    create_deployment!("Webservers") do
      notify_appsignal
    end
  end

  def create_deployment!(deployment_group_name, &block)
    client = Aws::CodeDeploy::Client.new(credentials)
    response = client.create_deployment(deployment_config(deployment_group_name))
    info "Deployment created."

    track_progress(response.deployment_id, &block)
  end

  def create_revision_file
    File.write(revision_file, revision)
  end

  def credentials
    { region: region, profile: profile }
  end

  def current_revision
    output, error, status = Open3.capture3("git", "rev-parse", treeish)

    if status.success?
      output.strip
    else
      raise RuntimeError, error
    end
  end

  def main_ref?
    ENV.fetch('GITHUB_REF', '') == 'refs/heads/main'
  end

  def tag_ref?
    ENV.fetch('GITHUB_REF', '') =~ /\Arefs\/tags\/[0-9]+(?:\.[0-9]+){1,2}\z/
  end

  def deploy_build?
    main_ref? || tag_ref?
  end

  def deployment_config(deployment_group_name)
    {
      application_name: application_name,
      deployment_group_name: deployment_group_name,
      revision: {
        revision_type: 'S3',
        s3_location: {
          bucket: release_bucket,
          key: deployment_key,
          bundle_type: 'tgz'
        },
      },
      deployment_config_name: deployment_config_name,
      description: description,
      ignore_application_stop_failures: true
    }
  end

  def deployment_config_name
    type = ENV.fetch('AWS_DEPLOYMENT_CONFIG_NAME', '0')

    case type
    when '2'
      'CodeDeployDefault.AllAtOnce'
    when '1'
      'CodeDeployDefault.HalfAtATime'
    else
      'CodeDeployDefault.OneAtATime'
    end
  end

  def deployment_key
    skip_build? ? latest_key : release_key
  end

  def description
    ENV.fetch('AWS_DEPLOYMENT_DESCRIPTION', '')
  end

  def extract_archive
    args = %w[tar]
    args.concat ['-C', tmpdir]
    args.concat ['-xf', archive_file]

    info "Extracting archive ..."
    Kernel.system(*args)
  end

  def info(message)
    $stdout.puts(message)
  end

  def latest_key
    "/latest.tar.gz"
  end

  def package_gems
    args = %w[bundle package --all --all-platforms --no-install]

    info "Packaging gems ..."
    Bundler.with_clean_env do
      Kernel.system(*args)
    end
  end

  def package_name
    "#{timestamp.strftime('%Y%m%d%H%M%S')}.tar.gz"
  end

  def package_path
    File.join('pkg', package_name)
  end

  def profile
    ENV.fetch('AWS_PROFILE', 'welsh-petitions')
  end

  def deploy_release?
    ENV.fetch('RELEASE', '1').to_i.nonzero?
  end

  def notify_appsignal
    if appsignal_push_api_key
      conn = Faraday.new(url: "https://push.appsignal.com")

      response = conn.post do |request|
        request.url '/1/markers'

        request.headers['Content-Type'] = 'application/json'

        request.params = {
          api_key: appsignal_push_api_key,
          name: appsignal_app_name,
          environment: 'production'
        }

        request.body = <<-JSON.strip_heredoc
          {
            "revision": "#{revision}",
            "repository": "master",
            "user": "#{username}"
          }
        JSON
      end

      if response.success?
        info "Notified AppSignal of deployment of #{revision}"
      end
    end
  end

  def appsignal_app_name
    ENV.fetch('APPSIGNAL_APP_NAME', "welsh-petitions-#{environment}")
  end

  def appsignal_push_api_key
    ENV.fetch('APPSIGNAL_PUSH_API_KEY', nil)
  end

  def username
    ENV['USER'] || ENV['USERNAME'] || 'unknown'
  end

  def region
    ENV.fetch('AWS_REGION', 'eu-west-1')
  end

  def release_bucket
    "welsh-petitions-deployments"
  end

  def release_key
    "#{environment}/#{release}.tar.gz"
  end

  def remove_archive
    args = %w[rm]
    args.concat [archive_file]

    info "Removing archive ..."
    Kernel.system(*args)
  end

  def remove_artifacts
    args = %w[rm -rf]
    args.concat %w[.bundle log tmp]

    info "Removing build artifacts ..."
    Kernel.system(*args)
  end

  def revision_file
    File.join(archive_path, 'REVISION')
  end

  def short_revision
    revision.first(7)
  end

  def commit_url
    "https://github.com/alphagov/e-petitions/commit/#{revision}"
  end

  def skip_build?
    ENV.fetch('SKIP_BUILD', '0').to_i.nonzero?
  end

  def skip_gems?
    ENV.fetch('SKIP_GEMS', '0').to_i.nonzero?
  end

  def track_progress(deployment_id, &block)
    start_deployment

    until completed?
      deployment  = get_deployment(deployment_id)
      status      = deployment.status

      if completed?
        deployment_complete(deployment, &block)
      elsif status == "InProgress"
        deployment_progress(deployment)
      end

      sleep(5)
    end
  end

  def start_deployment
    @client = Aws::CodeDeploy::Client.new(credentials)
    @completed = false
  end

  def get_deployment(deployment_id)
    response = @client.get_deployment(deployment_id: deployment_id)

    if response.successful?
      deployment = response.deployment_info
      @completed = !deployment.complete_time.nil?

      return deployment
    else
      raise "Error getting status for deployment: #{deployment_id}"
    end
  end

  def completed?
    completed
  end

  def deployment_complete(deployment, &block)
    id           = deployment.deployment_id
    created_at   = deployment.create_time
    completed_at = deployment.complete_time
    duration     = completed_at - created_at
    status       = deployment.status.downcase

    info format("Deployment %s %s in %0.2f seconds", id, status, duration)

    if status == "succeeded"
      yield if block_given?
    else
      exit(false)
    end
  end

  def deployment_progress(deployment)
    id         = deployment.deployment_id
    created_at = deployment.create_time
    duration   = Time.current - created_at
    overview   = deployment.deployment_overview
    progress   = %w[Pending InProgress Succeeded Failed Skipped]
    progress   = progress.map { |status| "#{status}: %d" }.join(", ")
    progress   = format(progress, *overview.values)

    info format("Deploying %s (%s) in %0.2f seconds", id, progress, duration)
  end

  def treeish
    ENV['TAG'] || ENV['BRANCH'] || 'HEAD'
  end

  def write_appspec
    File.write(appspec_file, appspec_yaml)
  end

  def write_scripts
    Dir.mkdir(scripts_path) unless Dir.exist?(scripts_path)

    write_script(application_start_script_file, application_start_script)
    write_script(application_stop_script_file, application_stop_script)
    write_script(before_install_script_file, before_install_script)
    write_script(after_install_script_file, after_install_script)
  end

  def write_script(path, script, mode = 0755)
    File.write(path, script)
    File.new(path).chmod(mode)
  end

  def scripts_path
    File.join(tmpdir, 'scripts')
  end

  def appspec_file
    File.join(tmpdir, 'appspec.yml')
  end

  def appspec_yaml
    ERB.new(File.read(config_file_path('appspec.yml'))).result(binding)
  end

  def config_file_path(name)
    File.expand_path("../package_builder/config/#{name}", __FILE__)
  end

  def application_start_script_file
    File.join(tmpdir, 'scripts', 'application_start')
  end

  def application_start_script
    File.read(script_file_path('application_start'))
  end

  def application_stop_script_file
    File.join(tmpdir, 'scripts', 'application_stop')
  end

  def application_stop_script
    File.read(script_file_path('application_stop'))
  end

  def before_install_script_file
    File.join(tmpdir, 'scripts', 'before_install')
  end

  def before_install_script
    ERB.new(File.read(script_file_path('before_install'))).result(binding)
  end

  def after_install_script_file
    File.join(tmpdir, 'scripts', 'after_install')
  end

  def after_install_script
    ERB.new(File.read(script_file_path('after_install'))).result(binding)
  end

  def script_file_path(name)
    File.expand_path("../package_builder/scripts/#{name}.sh", __FILE__)
  end
end
