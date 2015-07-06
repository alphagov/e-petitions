require 'tmpdir'
require 'active_support/core_ext/string/strip'
require 'aws-sdk'
require 'slack-notifier'

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
    start_time = Time.now

    release_obj.upload_file(package_path)

    duration = Time.now - start_time
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

      create_deployment! if deploy_release?
    end
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
    Kernel.system *args
  end

  def create_deployment!
    client = Aws::CodeDeploy::Client.new(credentials)
    response = client.create_deployment(deployment_config)
    info "Deployment created."

    track_progress(response.deployment_id) do |deployment_info|
      notify_appsignal
      notify_slack
    end
  end

  def create_revision_file
    File.write(revision_file, revision)
  end

  def credentials
    { region: region, profile: profile }
  end

  def deploy_branch?
    ENV.fetch('TRAVIS_BRANCH', 'master') == 'master'
  end

  def deploy_build?
    !pull_request? && deploy_branch?
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
    ENV.fetch('AWS_DEPLOYMENT_GROUP_NAME', 'RailsAppServers')
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

  def profile
    ENV.fetch('AWS_PROFILE', 'epetitions')
  end

  def deploy_release?
    ENV.fetch('RELEASE', '1').to_i.nonzero?
  end

  def notify_appsignal
    if appsignal_push_api_key
      args = %w[appsignal notify_of_deploy]
      args << %[--revision=#{revision}]
      args << %[--user=#{username}]
      args << %[--environment=production]
      args << %[--name=#{application_name}]

      info "Notifying AppSignal of deployment ..."
      Kernel.system *args
    end
  end

  def appsignal_push_api_key
    ENV.fetch('APPSIGNAL_PUSH_API_KEY', nil)
  end

  def username
    ENV['USER'] || ENV['USERNAME'] || 'unknown'
  end

  def notify_slack
    if slack_webhook
      notifier = Slack::Notifier.new(slack_webhook)
      notifier.ping slack_message, slack_options
    end
  end

  def slack_webhook
    ENV.fetch('SLACK_WEBHOOK_URL', nil)
  end

  def slack_message
    "Deployed revision <#{commit_url}|#{short_revision}> to <#{website_url}>"
  end

  def slack_options
    { channel: '#epetitions', username: 'deploy', icon_emoji: ':tada:' }
  end

  def pull_request?
    ENV.fetch('TRAVIS_PULL_REQUEST', 'false') != 'false'
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

  def short_revision
    revision.first(7)
  end

  def commit_url
    "https://github.com/alphagov/e-petitions/commit/#{revision}"
  end

  def website_url
    if environment == :production
      "https://petition.parliament.uk/"
    else
      "https://#{environment}.epetitions.website/"
    end
  end

  def skip_build?
    ENV.fetch('SKIP_BUILD', '0').to_i.nonzero?
  end

  def skip_gems?
    ENV.fetch('SKIP_GEMS', '0').to_i.nonzero?
  end

  def track_progress(deployment_id, &block)
    client = Aws::CodeDeploy::Client.new(credentials)
    completed = false

    while !completed do
      response = client.get_deployment(deployment_id: deployment_id)

      if response.successful?
        deployment = response.deployment_info
        status     = deployment.status
        completed  = !deployment.complete_time.nil?

        if completed
          deployment_complete(deployment)
        else
          if status == "InProgress"
            deployment_progress(deployment)
          end

          sleep(5)
        end

        yield deployment if status == "Succeeded"
      else
        raise RuntimeError, "Error getting status for deployment: #{deployment_id}"
      end
    end
  end

  def deployment_complete(deployment)
    id           = deployment.deployment_id
    created_at   = deployment.create_time
    completed_at = deployment.complete_time
    duration     = completed_at - created_at
    status       = deployment.status.downcase

    info ("Deployment %s %s in %0.2f seconds" % [id, status, duration])
  end

  def deployment_progress(deployment)
    id           = deployment.deployment_id
    created_at   = deployment.create_time
    duration     = Time.current - created_at
    overview     = deployment.deployment_overview
    progress     = "Pending: %d, InProgress: %d, Succeeded: %d, Failed: %d, Skipped: %d" % overview.values

    info ("Deploying %s (%s) in %0.2f seconds" % [id, progress, duration])
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
    write_script(common_functions_script_file, common_functions_script)
    write_script(deregister_from_elb_script_file, deregister_from_elb_script)
    write_script(register_with_elb_script_file, register_with_elb_script)
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
          - location: scripts/deregister_from_elb
            runas: root
          - location: scripts/application_stop
            runas: root
        AfterInstall:
          - location: scripts/after_install
            runas: root
        ApplicationStart:
          - location: scripts/application_start
            runas: root
          - location: scripts/register_with_elb
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
      su - deploy -c 'ln -nfs /home/deploy/epetitions/shared/assets /home/deploy/epetitions/releases/#{release}/public/assets'
      su - deploy -c 'ln -s /home/deploy/epetitions/releases/#{release} /home/deploy/epetitions/current_#{release}'
      su - deploy -c 'mv -Tf /home/deploy/epetitions/current_#{release} /home/deploy/epetitions/current'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle install --without development test --deployment --quiet'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle exec rake db:migrate'
      su - deploy -c 'cd /home/deploy/epetitions/current && bundle exec rake assets:precompile'

      # Run cron jobs only on workers, as webservers autoscale up and down.
      # ${SERVER_TYPE} is pre-populated for the deploy user by the build scripts
      su - deploy -c 'if [ ${SERVER_TYPE} = "worker" ] ; then cd /home/deploy/epetitions/current && bundle exec whenever -w ; else echo not running whenever ; fi'
    SCRIPT
  end

  def common_functions_script_file
    File.join(tmpdir, 'scripts', 'common_functions')
  end

  def deregister_from_elb_script_file
    File.join(tmpdir, 'scripts', 'deregister_from_elb')
  end

  def register_with_elb_script_file
    File.join(tmpdir, 'scripts', 'register_with_elb')
  end

  def common_functions_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      #
      # Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
      #
      # Licensed under the Apache License, Version 2.0 (the "License").
      # You may not use this file except in compliance with the License.
      # A copy of the License is located at
      #
      #  http://aws.amazon.com/apache2.0
      #
      # or in the "license" file accompanying this file. This file is distributed
      # on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
      # express or implied. See the License for the specific language governing
      # permissions and limitations under the License.

      # ELB_LIST defines which Elastic Load Balancers this instance should be part of.
      ELB_LIST="$ELB_NAME"

      # Under normal circumstances, you shouldn't need to change anything below this line.
      # -----------------------------------------------------------------------------

      export PATH="$PATH:/usr/bin:/usr/local/bin"

      # If true, all messages will be printed. If false, only fatal errors are printed.
      DEBUG=true

      # Number of times to check for a resouce to be in the desired state.
      WAITER_ATTEMPTS=60

      # Number of seconds to wait between attempts for resource to be in a state.
      WAITER_INTERVAL=1

      # AutoScaling Standby features at minimum require this version to work.
      MIN_CLI_VERSION='1.3.25'

      # Usage: get_instance_region
      #
      #   Writes to STDOUT the AWS region as known by the local instance.
      get_instance_region() {
          if [ -z "$AWS_REGION" ]; then
              AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document \
                  | grep -i region \
                  | awk -F'"' '{print $4}')
          fi

          echo $AWS_REGION
      }

      AWS_CLI="aws --region $(get_instance_region)"

      # Usage: autoscaling_group_name <EC2 instance ID>
      #
      #    Prints to STDOUT the name of the AutoScaling group this instance is a part of and returns 0. If
      #    it is not part of any groups, then it prints nothing. On error calling autoscaling, returns
      #    non-zero.
      autoscaling_group_name() {
          local instance_id=$1

          # This operates under the assumption that instances are only ever part of a single ASG.
          local autoscaling_name=$($AWS_CLI autoscaling describe-auto-scaling-instances \
              --instance-ids $instance_id \
              --output text \
              --query AutoScalingInstances[0].AutoScalingGroupName)

          if [ $? != 0 ]; then
              return 1
          elif [ "$autoscaling_name" == "None" ]; then
              echo ""
          else
              echo $autoscaling_name
          fi

          return 0
      }

      # Usage: autoscaling_enter_standby <EC2 instance ID> <ASG name>
      #
      #   Move <EC2 instance ID> into the Standby state in AutoScaling group <ASG name>. Doing so will
      #   pull it out of any Elastic Load Balancer that might be in front of the group.
      #
      #   Returns 0 if the instance was successfully moved to standby. Non-zero otherwise.
      autoscaling_enter_standby() {
          local instance_id=$1
          local asg_name=$2

          msg "Checking if this instance has already been moved in the Standby state"
          local instance_state=$(get_instance_state_asg $instance_id)
          if [ $? != 0 ]; then
              msg "Unable to get this instance's lifecycle state."
              return 1
          fi

          if [ "$instance_state" == "Standby" ]; then
              msg "Instance is already in Standby; nothing to do."
              return 0
          fi

          if [ "$instance_state" == "Pending:Wait" ]; then
              msg "Instance is Pending:Wait; nothing to do."
              return 0
          fi

          msg "Checking to see if ASG $asg_name will let us decrease desired capacity"
          local min_desired=$($AWS_CLI autoscaling describe-auto-scaling-groups \
              --auto-scaling-group-name $asg_name \
              --query 'AutoScalingGroups[0].[MinSize, DesiredCapacity]' \
              --output text)

          local min_cap=$(echo $min_desired | awk '{print $1}')
          local desired_cap=$(echo $min_desired | awk '{print $2}')

          if [ -z "$min_cap" -o -z "$desired_cap" ]; then
              msg "Unable to determine minimum and desired capacity for ASG $asg_name."
              msg "Attempting to put this instance into standby regardless."
          elif [ $min_cap == $desired_cap -a $min_cap -gt 0 ]; then
              local new_min=$(($min_cap - 1))
              msg "Decrementing ASG $asg_name's minimum size to $new_min"
              msg $($AWS_CLI autoscaling update-auto-scaling-group \
                  --auto-scaling-group-name $asg_name \
                  --min-size $new_min)
              if [ $? != 0 ]; then
                  msg "Failed to reduce ASG $asg_name's minimum size to $new_min. Cannot put this instance into Standby."
                  return 1
              fi
          fi

          msg "Putting instance $instance_id into Standby"
          $AWS_CLI autoscaling enter-standby \
              --instance-ids $instance_id \
              --auto-scaling-group-name $asg_name \
              --should-decrement-desired-capacity
          if [ $? != 0 ]; then
              msg "Failed to put instance $instance_id into Standby for ASG $asg_name."
              return 1
          fi

          msg "Waiting for move to Standby to finish"
          wait_for_state "autoscaling" $instance_id "Standby"
          if [ $? != 0 ]; then
              local wait_timeout=$(($WAITER_INTERVAL * $WAITER_ATTEMPTS))
              msg "Instance $instance_id did not make it to standby after $wait_timeout seconds"
              return 1
          fi

          return 0
      }

      # Usage: autoscaling_exit_standby <EC2 instance ID> <ASG name>
      #
      #   Attempts to move instance <EC2 instance ID> out of Standby and into InService. Returns 0 if
      #   successful.
      autoscaling_exit_standby() {
          local instance_id=$1
          local asg_name=$2

          msg "Checking if this instance has already been moved out of Standby state"
          local instance_state=$(get_instance_state_asg $instance_id)
          if [ $? != 0 ]; then
              msg "Unable to get this instance's lifecycle state."
              return 1
          fi

          if [ "$instance_state" == "InService" ]; then
              msg "Instance is already InService; nothing to do."
              return 0
          fi

          if [ "$instance_state" == "Pending:Wait" ]; then
              msg "Instance is Pending:Wait; nothing to do."
              return 0
          fi

          msg "Moving instance $instance_id out of Standby"
          $AWS_CLI autoscaling exit-standby \
              --instance-ids $instance_id \
              --auto-scaling-group-name $asg_name
          if [ $? != 0 ]; then
              msg "Failed to put instance $instance_id back into InService for ASG $asg_name."
              return 1
          fi

          msg "Waiting for exit-standby to finish"
          wait_for_state "autoscaling" $instance_id "InService"
          if [ $? != 0 ]; then
              local wait_timeout=$(($WAITER_INTERVAL * $WAITER_ATTEMPTS))
              msg "Instance $instance_id did not make it to InService after $wait_timeout seconds"
              return 1
          fi

          return 0
      }

      # Usage: get_instance_state_asg <EC2 instance ID>
      #
      #    Gets the state of the given <EC2 instance ID> as known by the AutoScaling group it's a part of.
      #    Health is printed to STDOUT and the function returns 0. Otherwise, no output and return is
      #    non-zero.
      get_instance_state_asg() {
          local instance_id=$1

          local state=$($AWS_CLI autoscaling describe-auto-scaling-instances \
              --instance-ids $instance_id \
              --query "AutoScalingInstances[?InstanceId == \'$instance_id\'].LifecycleState | [0]" \
              --output text)
          if [ $? != 0 ]; then
              return 1
          else
              echo $state
              return 0
          fi
      }

      reset_waiter_timeout() {
          local elb=$1

          local health_check_values=$($AWS_CLI elb describe-load-balancers \
              --load-balancer-name $elb \
              --query 'LoadBalancerDescriptions[0].HealthCheck.[HealthyThreshold, Interval]' \
              --output text)

          WAITER_ATTEMPTS=$(echo $health_check_values | awk '{print $1}')
          WAITER_INTERVAL=$(echo $health_check_values | awk '{print $2}')
      }

      # Usage: wait_for_state <service> <EC2 instance ID> <state name> [ELB name]
      #
      #    Waits for the state of <EC2 instance ID> to be in <state> as seen by <service>. Returns 0 if
      #    it successfully made it to that state; non-zero if not. By default, checks $WAITER_ATTEMPTS
      #    times, every $WAITER_INTERVAL seconds. If giving an [ELB name] to check under, these are reset
      #    to that ELB's HealthThreshold and Interval values.
      wait_for_state() {
          local service=$1
          local instance_id=$2
          local state_name=$3
          local elb=$4

          local instance_state_cmd
          if [ "$service" == "elb" ]; then
              instance_state_cmd="get_instance_health_elb $instance_id $elb"
              reset_waiter_timeout $elb
          elif [ "$service" == "autoscaling" ]; then
              instance_state_cmd="get_instance_state_asg $instance_id"
          else
              msg "Cannot wait for instance state; unknown service type, '$service'"
              return 1
          fi

          msg "Checking $WAITER_ATTEMPTS times, every $WAITER_INTERVAL seconds, for instance $instance_id to be in state $state_name"

          local instance_state=$($instance_state_cmd)
          local count=1

          msg "Instance is currently in state: $instance_state"
          while [ "$instance_state" != "$state_name" ]; do
              if [ $count -ge $WAITER_ATTEMPTS ]; then
                  local timeout=$(($WAITER_ATTEMPTS * $WAITER_INTERVAL))
                  msg "Instance failed to reach state, $state_name within $timeout seconds"
                  return 1
              fi

              sleep $WAITER_INTERVAL

              instance_state=$($instance_state_cmd)
              count=$(($count + 1))
              msg "Instance is currently in state: $instance_state"
          done

          return 0
      }

      # Usage: get_instance_health_elb <EC2 instance ID> <ELB name>
      #
      #    Gets the health of the given <EC2 instance ID> as known by <ELB name>. If it's a valid health
      #    status (one of InService|OutOfService|Unknown), then the health is printed to STDOUT and the
      #    function returns 0. Otherwise, no output and return is non-zero.
      get_instance_health_elb() {
          local instance_id=$1
          local elb_name=$2

          msg "Checking status of instance '$instance_id' in load balancer '$elb_name'"

          # If describe-instance-health for this instance returns an error, then it's not part of
          # this ELB. But, if the call was successful let's still double check that the status is
          # valid.
          local instance_status=$($AWS_CLI elb describe-instance-health \
              --load-balancer-name $elb_name \
              --instances $instance_id \
              --query 'InstanceStates[].State' \
              --output text 2>/dev/null)

          if [ $? == 0 ]; then
              case "$instance_status" in
                  InService|OutOfService|Unknown)
                      echo -n $instance_status
                      return 0
                      ;;
                  *)
                      msg "Instance '$instance_id' not part of ELB '$elb_name'"
                      return 1
              esac
          fi
      }

      # Usage: validate_elb <EC2 instance ID> <ELB name>
      #
      #    Validates that the Elastic Load Balancer with name <ELB name> exists, is describable, and
      #    contains <EC2 instance ID> as one of its instances.
      #
      #    If any of these checks are false, the function returns non-zero.
      validate_elb() {
          local instance_id=$1
          local elb_name=$2

          # Get the list of active instances for this LB.
          local elb_instances=$($AWS_CLI elb describe-load-balancers \
              --load-balancer-name $elb_name \
              --query 'LoadBalancerDescriptions[*].Instances[*].InstanceId' \
              --output text)
          if [ $? != 0 ]; then
              msg "Couldn't describe ELB instance named '$elb_name'"
              return 1
          fi

          msg "Checking health of '$instance_id' as known by ELB '$elb_name'"
          local instance_health=$(get_instance_health_elb $instance_id $elb_name)
          if [ $? != 0 ]; then
              return 1
          fi

          return 0
      }

      # Usage: get_elb_list <EC2 instance ID>
      #
      #   Finds all the ELBs that this instance is registered to. After execution, the variable
      #   "INSTANCE_ELBS" will contain the list of load balancers for the given instance.
      #
      #   If the given instance ID isn't found registered to any ELBs, the function returns non-zero
      get_elb_list() {
          local instance_id=$1

          local elb_list=""

          local all_balancers=$($AWS_CLI elb describe-load-balancers \
              --query LoadBalancerDescriptions[*].LoadBalancerName \
              --output text | sed -e $'s/\t/ /g')

          for elb in $all_balancers; do
              local instance_health
              instance_health=$(get_instance_health_elb $instance_id $elb)
              if [ $? == 0 ]; then
                  elb_list="$elb_list $elb"
              fi
          done

          if [ -z "$elb_list" ]; then
              return 1
          else
              msg "Got load balancer list of: $elb_list"
              INSTANCE_ELBS=$elb_list
              return 0
          fi
      }

      # Usage: deregister_instance <EC2 instance ID> <ELB name>
      #
      #   Deregisters <EC2 instance ID> from <ELB name>.
      deregister_instance() {
          local instance_id=$1
          local elb_name=$2

          $AWS_CLI elb deregister-instances-from-load-balancer \
              --load-balancer-name $elb_name \
              --instances $instance_id 1> /dev/null

          return $?
      }

      # Usage: register_instance <EC2 instance ID> <ELB name>
      #
      #   Registers <EC2 instance ID> to <ELB name>.
      register_instance() {
          local instance_id=$1
          local elb_name=$2

          $AWS_CLI elb register-instances-with-load-balancer \
              --load-balancer-name $elb_name \
              --instances $instance_id 1> /dev/null

          return $?
      }

      # Usage: check_cli_version [version-to-check] [desired version]
      #
      #   Without any arguments, checks that the installed version of the AWS CLI is at least at version
      #   $MIN_CLI_VERSION. Returns non-zero if the version is not high enough.
      check_cli_version() {
          if [ -z $1 ]; then
              version=$($AWS_CLI --version 2>&1 | cut -f1 -d' ' | cut -f2 -d/)
          else
              version=$1
          fi

          if [ -z "$2" ]; then
              min_version=$MIN_CLI_VERSION
          else
              min_version=$2
          fi

          x=$(echo $version | cut -f1 -d.)
          y=$(echo $version | cut -f2 -d.)
          z=$(echo $version | cut -f3 -d.)

          min_x=$(echo $min_version | cut -f1 -d.)
          min_y=$(echo $min_version | cut -f2 -d.)
          min_z=$(echo $min_version | cut -f3 -d.)

          msg "Checking minimum required CLI version (${min_version}) against installed version ($version)"

          if [ $x -lt $min_x ]; then
              return 1
          elif [ $y -lt $min_y ]; then
              return 1
          elif [ $y -gt $min_y ]; then
              return 0
          elif [ $z -ge $min_z ]; then
              return 0
          else
              return 1
          fi
      }

      # Usage: msg <message>
      #
      #   Writes <message> to STDERR only if $DEBUG is true, otherwise has no effect.
      msg() {
          local message=$1
          $DEBUG && echo $message 1>&2
      }

      # Usage: error_exit <message>
      #
      #   Writes <message> to STDERR as a "fatal" and immediately exits the currently running script.
      error_exit() {
          local message=$1

          echo "[FATAL] $message" 1>&2
          exit 1
      }

      # Usage: get_instance_id
      #
      #   Writes to STDOUT the EC2 instance ID for the local instance. Returns non-zero if the local
      #   instance metadata URL is inaccessible.
      get_instance_id() {
          curl -s http://169.254.169.254/latest/meta-data/instance-id
          return $?
      }
    SCRIPT
  end

  def deregister_from_elb_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      #
      # Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
      #
      # Licensed under the Apache License, Version 2.0 (the "License").
      # You may not use this file except in compliance with the License.
      # A copy of the License is located at
      #
      #  http://aws.amazon.com/apache2.0
      #
      # or in the "license" file accompanying this file. This file is distributed
      # on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
      # express or implied. See the License for the specific language governing
      # permissions and limitations under the License.

      if [ "$SERVER_TYPE" == "worker" ]; then
        msg "Workers are not registered with a load balancer"
        exit 0
      fi

      . $(dirname $0)/common_functions

      msg "Running AWS CLI with region: $(get_instance_region)"

      # get this instance's ID
      INSTANCE_ID=$(get_instance_id)
      if [ $? != 0 -o -z "$INSTANCE_ID" ]; then
          error_exit "Unable to get this instance's ID; cannot continue."
      fi

      # Get current time
      msg "Started $(basename $0) at $(/bin/date "+%F %T")"
      start_sec=$(/bin/date +%s.%N)

      msg "Checking if instance $INSTANCE_ID is part of an AutoScaling group"
      asg=$(autoscaling_group_name $INSTANCE_ID)
      if [ $? == 0 -a -n "$asg" ]; then
          msg "Found AutoScaling group for instance $INSTANCE_ID: $asg"

          msg "Checking that installed CLI version is at least at version required for AutoScaling Standby"
          check_cli_version
          if [ $? != 0 ]; then
              error_exit "CLI must be at least version ${MIN_CLI_X}.${MIN_CLI_Y}.${MIN_CLI_Z} to work with AutoScaling Standby"
          fi

          msg "Attempting to put instance into Standby"
          autoscaling_enter_standby $INSTANCE_ID $asg
          if [ $? != 0 ]; then
              error_exit "Failed to move instance into standby"
          else
              msg "Instance is in standby"
              exit 0
          fi
      fi

      msg "Instance is not part of an ASG, continuing..."

      msg "Checking that user set at least one load balancer"
      if test -z "$ELB_LIST"; then
          error_exit "Must have at least one load balancer to deregister from"
      fi

      # Loop through all LBs the user set, and attempt to deregister this instance from them.
      for elb in $ELB_LIST; do
          msg "Checking validity of load balancer named '$elb'"
          validate_elb $INSTANCE_ID $elb
          if [ $? != 0 ]; then
              msg "Error validating $elb; cannot continue with this LB"
              continue
          fi

          msg "Deregistering $INSTANCE_ID from $elb"
          deregister_instance $INSTANCE_ID $elb

          if [ $? != 0 ]; then
              error_exit "Failed to deregister instance $INSTANCE_ID from ELB $elb"
          fi
      done

      # Wait for all Deregistrations to finish
      msg "Waiting for instance to de-register from its load balancers"
      for elb in $ELB_LIST; do
          wait_for_state "elb" $INSTANCE_ID "OutOfService" $elb
          if [ $? != 0 ]; then
              error_exit "Failed waiting for $INSTANCE_ID to leave $elb"
          fi
      done

      msg "Finished $(basename $0) at $(/bin/date "+%F %T")"

      end_sec=$(/bin/date +%s.%N)
      elapsed_seconds=$(echo "$end_sec - $start_sec" | /usr/bin/bc)

      msg "Elapsed time: $elapsed_seconds"
    SCRIPT
  end

  def register_with_elb_script
    <<-SCRIPT.strip_heredoc
      #!/usr/bin/env bash
      #
      # Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
      #
      # Licensed under the Apache License, Version 2.0 (the "License").
      # You may not use this file except in compliance with the License.
      # A copy of the License is located at
      #
      #  http://aws.amazon.com/apache2.0
      #
      # or in the "license" file accompanying this file. This file is distributed
      # on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
      # express or implied. See the License for the specific language governing
      # permissions and limitations under the License.

      if [ "$SERVER_TYPE" == "worker" ]; then
        msg "Workers are not registered with a load balancer"
        exit 0
      fi

      . $(dirname $0)/common_functions

      msg "Running AWS CLI with region: $(get_instance_region)"

      # get this instance's ID
      INSTANCE_ID=$(get_instance_id)
      if [ $? != 0 -o -z "$INSTANCE_ID" ]; then
          error_exit "Unable to get this instance's ID; cannot continue."
      fi

      # Get current time
      msg "Started $(basename $0) at $(/bin/date "+%F %T")"
      start_sec=$(/bin/date +%s.%N)

      msg "Checking if instance $INSTANCE_ID is part of an AutoScaling group"
      asg=$(autoscaling_group_name $INSTANCE_ID)
      if [ $? == 0 -a -n "$asg" ]; then
          msg "Found AutoScaling group for instance $INSTANCE_ID: $asg"

          msg "Checking that installed CLI version is at least at version required for AutoScaling Standby"
          check_cli_version
          if [ $? != 0 ]; then
              error_exit "CLI must be at least version ${MIN_CLI_X}.${MIN_CLI_Y}.${MIN_CLI_Z} to work with AutoScaling Standby"
          fi

          msg "Attempting to move instance out of Standby"
          autoscaling_exit_standby $INSTANCE_ID $asg
          if [ $? != 0 ]; then
              error_exit "Failed to move instance out of standby"
          else
              msg "Instance is no longer in Standby"
              exit 0
          fi
      fi

      msg "Instance is not part of an ASG, continuing..."

      msg "Checking that user set at least one load balancer"
      if test -z "$ELB_LIST"; then
          error_exit "Must have at least one load balancer to deregister from"
      fi

      # Loop through all LBs the user set, and attempt to register this instance to them.
      for elb in $ELB_LIST; do
          msg "Checking validity of load balancer named '$elb'"
          validate_elb $INSTANCE_ID $elb
          if [ $? != 0 ]; then
              msg "Error validating $elb; cannot continue with this LB"
              continue
          fi

          msg "Registering $INSTANCE_ID to $elb"
          register_instance $INSTANCE_ID $elb

          if [ $? != 0 ]; then
              error_exit "Failed to register instance $INSTANCE_ID from ELB $elb"
          fi
      done

      # Wait for all Registrations to finish
      msg "Waiting for instance to register to its load balancers"
      for elb in $ELB_LIST; do
          wait_for_state "elb" $INSTANCE_ID "InService" $elb
          if [ $? != 0 ]; then
              error_exit "Failed waiting for $INSTANCE_ID to return to $elb"
          fi
      done

      msg "Finished $(basename $0) at $(/bin/date "+%F %T")"

      end_sec=$(/bin/date +%s.%N)
      elapsed_seconds=$(echo "$end_sec - $start_sec" | /usr/bin/bc)

      msg "Elapsed time: $elapsed_seconds"
    SCRIPT
  end
end
