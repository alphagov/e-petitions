require 'tmpdir'
require 'active_support/core_ext/string/strip'
require 'aws-sdk'

class PackageBuilder
  class << self
    def build!(environment = :staging)
      new(environment).build!
    end

    def deploy!(environment)
      new(environment).deploy!
    end
  end

  attr_reader :environment, :release, :revision, :tmpdir, :timestamp

  def initialize(enviroment)
    @environment = enviroment.to_s
    @revision    = %x[git rev-parse #{treeish}].strip
    @tmpdir      = Dir.mktmpdir
    @timestamp   = Time.now.getutc
    @release     = @timestamp.strftime('%Y%m%d%H%I%S')
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
      precompile_assets
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
    latest_obj = bucket.object(latest_key)

    info "Uploading package #{package_name} to S3 ..."
    start_time = Time.now

    release_obj.upload_file(package_path)

    duration = Time.now - start_time
    info "Upload completed in #{duration} seconds."

    info "Copying file #{release_key} to #{latest_key} ..."
    latest_obj.copy_from(copy_source: "#{release_bucket}/#{release_key}")
  end

  def deploy!
    unless skip_build?
      build!
      upload!
    end

    create_deployment! if deploy_release?
  end

  private

  def application_name
    "#{ENV.fetch('AWS_DEPLOYMENT_APP_NAME', 'epetitions')}-#{environment}"
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
    Kernel.system *args
  end

  def create_archive
    args = %w[git archive]
    args.concat ['--format', 'tar']
    args.concat ['--prefix', 'source/']
    args.concat ['--output', archive_file]
    args.concat [treeish]

    info "Creating archive ..."
    Kernel.system *args
  end

  def create_deployment!
    client = Aws::CodeDeploy::Client.new(credentials)
    client.create_deployment(deployment_config)
    info "Deployment created."
  end

  def create_revision_file
    File.write(revision_file, revision)
  end

  def credentials
    { region: region, profile: profile }
  end

  def deployment_config
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

  def deployment_group_name
    ENV.fetch('AWS_DEPLOYMENT_GROUP_NAME', 'Webservers')
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
    Kernel.system *args
  end

  def info(message)
    $stdout.puts(message)
  end

  def latest_key
    "/latest.tar.gz"
  end

  def package_gems
    args = %w[bundle package --all --all-platforms]

    info "Packaging gems ..."
    Bundler.with_clean_env do
      Kernel.system *args
    end
  end

  def package_name
    "#{timestamp.strftime('%Y%m%d%H%I%S')}.tar.gz"
  end

  def package_path
    File.join('pkg', package_name)
  end

  def precompile_assets
    args = %w[bundle exec rake assets:precompile]

    info "Precompiling assets ..."
    Bundler.with_clean_env do
      Kernel.system *args
    end
  end

  def profile
    ENV.fetch('AWS_PROFILE', 'epetitions')
  end

  def deploy_release?
    ENV.fetch('RELEASE', '1').to_i.nonzero?
  end

  def region
    ENV.fetch('AWS_REGION', 'eu-west-1')
  end

  def release_bucket
    "ubxd-epetitions-#{environment}-releases"
  end

  def release_key
    "#{release}.tar.gz"
  end

  def remove_archive
    args = %w[rm]
    args.concat [archive_file]

    info "Removing archive ..."
    Kernel.system *args
  end

  def remove_artifacts
    args = %w[rm -rf]
    args.concat %w[log tmp]

    info "Removing build artifacts ..."
    Kernel.system *args
  end

  def revision_file
    File.join(archive_path, 'REVISION')
  end

  def skip_build?
    ENV.fetch('SKIP_BUILD', '0').to_i.nonzero?
  end

  def skip_gems?
    ENV.fetch('SKIP_GEMS', '0').to_i.nonzero?
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
    <<-FILE.strip_heredoc
      version: 0.0
      os: linux
      files:
        - source: ./source
          destination: /home/deploy/epetitions/releases/#{release}

      hooks:
        ApplicationStop:
          - location: scripts/application_stop
            runas: root
        AfterInstall:
          - location: scripts/after_install
            runas: root
        ApplicationStart:
          - location: scripts/application_start
            runas: root
    FILE
  end

  def application_start_script_file
    File.join(tmpdir, 'scripts', 'application_start')
  end

  def application_start_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      /etc/init.d/epetitions start
    SCRIPT
  end

  def application_stop_script_file
    File.join(tmpdir, 'scripts', 'application_stop')
  end

  def application_stop_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      /etc/init.d/epetitions stop || true
    SCRIPT
  end

  def after_install_script_file
    File.join(tmpdir, 'scripts', 'after_install')
  end

  def after_install_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      chown -R deploy:deploy /home/deploy/epetitions/releases/#{release}

      if [ ! -e /home/deploy/epetitions/releases/#{release}/tmp ]; then
        su - deploy -c 'mkdir /home/deploy/epetitions/releases/#{release}/tmp'
      fi

      su - deploy -c 'ln -nfs /home/deploy/epetitions/shared/log /home/deploy/epetitions/releases/#{release}/log'
      su - deploy -c 'ln -nfs /home/deploy/epetitions/shared/bundle /home/deploy/epetitions/releases/#{release}/vendor/bundle'
      su - deploy -c 'ln -s /home/deploy/epetitions/releases/#{release} /home/deploy/epetitions/current_#{release}'
      su - deploy -c 'mv -Tf /home/deploy/epetitions/current_#{release} /home/deploy/epetitions/current'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle install --without development test --deployment --quiet'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle exec rake db:migrate'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle exec whenever -w'
    SCRIPT
  end
end
