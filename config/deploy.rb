# config valid for current version and patch releases of Capistrano
lock "~> 3.15.0"

set :stages, %w(production)

set :application,     'herbalife'
set :repo_url,        'git@github.com:TechWrightLabs/herbalife.git'
set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    2
set :use_private_ip,  ENV['USE_PRIVATE_IP'] || false

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :environment,     fetch(:stage)
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/#{fetch(:application)}"
set :assets_role,     [:web]
set :migration_role,  :app
set :keep_assets,     2
set :rails_assets_groups, :assets
set :assets_manifests, ['app/assets/config/manifest.js']
set :conditionally_migrate, true
set :migration_servers, -> { primary(fetch(:migration_role)) }

# set :rvm_path, '/home/deploy/.rvm'

# puma configs
set :puma_user, fetch(:user)
set :puma_rackup, -> { File.join(current_path, 'config.ru') }
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"    #accept array for multi-bind
set :puma_control_app, false
set :puma_conf, "#{shared_path}/config/puma.rb"
set :puma_access_log, "#{shared_path}/log/puma_access.log"
set :puma_error_log, "#{shared_path}/log/puma_error.log"
set :puma_role, :web
set :puma_env, fetch(:stage)
set :puma_worker_timeout, nil
set :puma_init_active_record, true
set :puma_preload_app, true
set :puma_tag, fetch(:application)
set :puma_restart_command, 'bundle exec --keep-file-descriptors puma'
# set :puma_restart_command, 'bundle exec puma'
set :puma_restart_command_with_sudo, false

# Nginx Config
set :nginx_config_name, "#{fetch(:application)}_#{fetch(:stage)}"
set :nginx_flags, 'fail_timeout=0'
set :nginx_http_flags, fetch(:nginx_flags)
set :nginx_server_name, "localhost #{fetch(:application)}.local"
set :nginx_sites_available_path, '/etc/nginx/sites-available'
set :nginx_sites_enabled_path, '/etc/nginx/sites-enabled'
set :nginx_ssl_certificate, "#{shared_path}/ssl/certs/#{fetch(:nginx_config_name)}.crt"
set :nginx_ssl_certificate_key, "#{shared_path}/ssl/private/#{fetch(:nginx_config_name)}.key"
set :nginx_use_ssl, (fetch(:stage) == 'production')

set :ssh_options,     { user: fetch(:user), keys: "~/.ssh/id_rsa" }
set :keep_releases, 5
set :bundle_jobs,   4

# SIDEKICK CONFIGURATION
# set :init_system, :systemd
# set :sidekiq_pid, File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
# set :sidekiq_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
# set :sidekiq_log, File.join(shared_path, 'log', 'sidekiq.log')
# set :sidekiq_config, File.join(shared_path, 'config', 'sidekiq.yml')
# set :sidekiq_roles, :worker
# set :sidekiq_user, fetch(:user)
# set :sidekiq_default_hooks, true
# set :sidekiq_service_unit_name, 'sidekiq'
# set :sidekiq_service_unit_user, fetch(:user)
# set :sidekiq_enable_lingering, true

# if fetch(:nginx_use_ssl)
#   set :linked_files, %w{.env config/puma.rb config/database.yml config/sidekiq.yml config/master.key config/cable.yml ssl/certs/tournity_production.crt ssl/private/tournity_production.key}
# else
  set :linked_files, %w{.env config/puma.rb config/database.yml config/master.key}
# end

set :linked_dirs,  %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets storage}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

# Bugsnag settings
# set :bugsnag_api_key, ENV['BUGSNAG_API_KEY']
# set :app_version, ENV['RELEASE_VERSION']
# set :bugsnag_env, fetch(:stage)

# Appsignal settings
# set :appsignal_config, name: "Tournity #{fetch(:stage)}"
# set :appsignal_env, fetch(:stage)
# set :appsignal_revision, `git log --pretty=format:'%h' -n 1 #{fetch(:branch)}`

# NewRelic One settings
# set :newrelic_appname, "Tournity (#{fetch(:stage).capitalize})"

# WHENEVER
# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# SSHKit.config.command_map[:sidekiq] = "bundle exec sidekiq"
# SSHKit.config.command_map[:sidekiqctl] = "bundle exec sidekiqctl"

# after "deploy:updated", "newrelic:notice_deployment"