require 'byebug'
require 'socket'
# require 'aws-sdk-rails'
require 'open-uri'
require 'openssl'
require "dotenv"
require 'httparty'
Dotenv.load
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

namespace :load do
  task :defaults do
    set :enable_by_each_restart, -> { true }
    set :exclude_elb_restart, -> { [] }
    set :aws_health_check_limit, -> { 30 }
  end
end

def init_aws!
  params = {
    aws_region: ENV.fetch("AWS_REGION"),
    aws_access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY")
  }

  Aws.use_bundled_cert!
  Aws.config.update({ region: params[:aws_region], credentials: Aws::Credentials.new(params[:aws_access_key_id], params[:aws_secret_access_key]) })
end

def aws_filters
  tags = fetch(:aws_instances_tags, {})
  tags.keys.map { |key| { 'name' => "tag:#{key}", 'values' => tags[key].is_a?(Array) ? tags[key] : [tags[key]] } }
end

def aws_instances
  Aws::EC2::Client.new.describe_instances(filters: aws_filters).reservations.map(&:instances).flatten
end

def find_instance_by_ip(ip)
  aws_instances.select { |instance| fetch(:use_private_ip) ? (instance.private_ip_address == ip) : (instance.public_ip_address == ip) }.first
end

def find_instance_by_id(instance_id)
  aws_instances.select { |instance| instance.id == instance_id }.first
end

def aws_pull_out_from_elb(instance_id)
  fetch(:aws_target_group_arns, []).each do |arn|
    Aws::ElasticLoadBalancingV2::Client.new.deregister_targets({
      target_group_arn: arn,
      targets: [{ id: instance_id }]
    })
    puts "Dettached instance: #{instance_id} from #{arn}"
  end
end

def aws_put_up_to_elb(instance_id)
  fetch(:aws_target_group_arns, []).each do |arn|
    Aws::ElasticLoadBalancingV2::Client.new.register_targets({
      target_group_arn: arn,
      targets: [{ id: instance_id }]
    })
    puts "Attached instance: #{instance_id} to #{arn}"
  end
end

def check_instance_health(ip)
  endpoint = "http://#{ip}/health"
  retries = 5
  begin
    response = open(endpoint).read
    if response.body.to_s.index('ok')
      puts "IP: #{ip} is healthy."
      return true
    end
  rescue
    retries -= 1
    if retries == 0
      abort 'Fail to health check'
    else
      puts 'waiting health check...'
      sleep 10
    end
  end
end

def check_target_group_state(instance_id, to: 'healthy', interval: 15, max_check: nil)
  state = nil
  times = 0
  max_check ||= fetch(:aws_health_check_limit)
  while(state != [to])
    puts "Checking #{instance_id}'s state on ELB..."
    state = aws_get_instance_elb_status(instance_id)
    times += 1
    if max_check <= times
      abort("Instance state checking #{instance_id} over max count")
      break
    else
      puts "Got state #{state}, keep checking..."
      sleep(interval)
    end
  end
end

def aws_get_instance_elb_status(instance_id)
  fetch(:aws_target_group_arns, []).map do |arn|
    Aws::ElasticLoadBalancingV2::Client.new.describe_target_health({
      target_group_arn: arn,
      targets: [{ id: instance_id }]
    }).target_health_descriptions[0].target_health.state
  end.uniq
end

def restart! server
  on(server.to_s) do
    within current_path do
      puts "Restarting Puma in #{current_path}"
      restart_command = fetch(:puma_restart_command).split(' ').collect(&:to_sym)
      if fetch(:puma_restart_command_with_sudo)
        # We preprocess the command with SSHKit::Command to allow 'passenger-config' to be transformed with the command map.
        restart_command = [:sudo, SSHKit::Command.new(*restart_command).to_s]
      end
      execute(*restart_command)
      # invoke!('puma:restart')
    end
  end
end

namespace :ec2 do
  desc 'load roles based on EC2 instance tags'
  task :load_tagged_roles do
    init_aws!
    aws_instances.each do |server|
      next unless server.tags || (server.tags.select{ |t| t[:key] == 'Version'}[0].present? && server.tags.select{ |t| t[:key] == 'Env'}[0].present?) || server.state == 'running'
      apps_roles  = server.tags.select{ |t| t[:key] == 'Roles'}[0][:value].split(',').map(&:to_sym)
      server get_server_ip(server), user: fetch(:user), roles: apps_roles
    end
  end

  def get_server_ip server
    fetch(:use_private_ip)? server.private_ip_address : server.public_ip_address
  end

  desc 'list roles and hosts'
  task :list_roles => :load_tagged_roles do
    on roles(:all) do |host|
      info "Host #{host} (#{host.roles.to_a.join(', ')})"
    end
  end

  # after 'deploy:set_rails_env', 'ec2:load_tagged_roles'
end

namespace :deploy do
  task :upload_shared_files do
    on roles(:app), in: :sequence, wait: 10 do
      config_url = "https://#{ENV.fetch('GITHUB_PERSONAL_ACCESS_TOKEN')}@raw.githubusercontent.com/TechWrightLabs/devops/master/#{fetch(:application)}/#{fetch(:stage)}"
      fetch(:linked_files).each do |linked_file|
        next if linked_file == 'config/puma.rb'
        unless test("[ -f #{shared_path}/#{linked_file} ]") && !(ENV.fetch('FORCE_UPLOAD', '0') == '1')
          response = HTTParty.get("#{config_url}/#{linked_file}")
          unless linked_file.include?('/')
            _tmp_file_path = "/tmp/#{linked_file}"
          else
            _linked_file = linked_file.split('/').map(&:strip)[1]
            _tmp_file_path = "/tmp/#{_linked_file}"
          end
          File.open(_tmp_file_path, 'w') { |file| file.write(response.body) }
          File.delete("#{shared_path}/#{linked_file}") if File.exists?("#{shared_path}/#{linked_file}")
          upload! _tmp_file_path, "#{shared_path}/#{linked_file}"
          File.delete(_tmp_file_path)
        end
      end
    end
  end

  task :init_by_each_restart do
    if fetch(:enable_by_each_restart) == true
      Rake::Task['deploy:restart'].clear
    end
  end

  task :by_each_restart do
    run_locally do
      roles(:web).each do |server|
        on(server.to_s) do
          next unless fetch(:enable_by_each_restart) == true
          if fetch(:exclude_elb_restart, []).include?(server.to_s)
            restart!
            next
          end
          init_aws!
          ip = Socket::getaddrinfo(server.to_s, 'echo', Socket::AF_INET)[0][3]
          instance = find_instance_by_ip(ip)
          if instance
            aws_pull_out_from_elb(instance.instance_id)
            check_target_group_state(instance.instance_id, to: 'unused', interval: 30, max_check: 30)
            restart!(server)
            sleep(5)
            check_instance_health(ip)
            aws_put_up_to_elb(instance.instance_id)
            check_target_group_state(instance.instance_id, to: 'healthy', interval: 20)
          else
            abort "Instance not found! ip=#{ip} server=#{server} filters=#{fetch(:aws_instances_tags, {}).to_json}"
          end
        end
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      invoke!('puma:restart')
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Compile Assets'
  task :precompile do
    on roles(:web), in: :sequence, wait: 5 do
      within release_path do
        invoke!('compile_assets') 
      end
    end
  end

  desc 'Refresh Elasticsearch'
  task :refresh_elasticsearch do
    on roles(:db), in: :sequence, wait: 5 do
      within current_path do
        with :rails_env => fetch(:rails_env) do
          # puts 'Initializing AWS connection'
          # init_aws!
          puts "Refresh Elasticsearch in #{fetch(:rails_env)} servers."
          # rake 'elasticsearch:refresh'
          execute :bundle, ("exec rake elasticsearch:refresh")
        end
      end
    end
  end

  # after  :finishing,    :compile_assets
  # after  :finishing,    :precompile
  # after  :finishing,    :restart
end

# after  'deploy:finishing', 'deploy:cleanup'
before 'deploy:check:linked_dirs', 'deploy:upload_shared_files'

unless ENV.fetch('DISABLE_ROLLING_RESTART', "0") == "1"
  # before 'deploy:publishing', 'deploy:init_by_each_restart'
  # after 'deploy:publishing', 'deploy:by_each_restart'
end

if ENV.fetch('REFRESH_ELASTICSEARCH', "0") == "1"
  # after 'deploy:cleanup', 'deploy:refresh_elasticsearch'
end
