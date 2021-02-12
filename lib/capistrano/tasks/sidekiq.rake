# namespace :sidekiq do
# #   task :restart do
# #     invoke 'sidekiq:stop'
# #     invoke 'sidekiq:start'
# #   end

# #   # before 'deploy:finished', 'sidekiq:restart'

# #   task :stop do
# #     on roles(:worker) do
# #       pid = p capture "ps -ef | grep sidekiq | grep busy | grep -v grep | awk '{print $2}'"
# #       execute("kill -9 #{pid}") unless pid.empty?
# #     end
# #   end

# #   task :start do
# #     on roles(:worker) do
# #       within current_path do
# #         execute :bundle, "exec sidekiq -e #{fetch(:stage)} -L #{shared_path}/log/sidekiq.log -d"
# #       end
# #     end
# #   end

# #   task :log do
# #     on roles(:worker) do
# #       execute "touch #{shared_path}/log/sidekiq.log"
# #     end
# #   end

# #   # before :start, :log

#   desc "Quiet sidekiq (stop fetching new tasks from Redis)"
#   task :quiet do
#     on roles(:worker) do
#       execute :sudo, :systemctl, :kill, "-s", "TSTP", fetch(:sidekiq_service_unit_name)
#     end
#   end

#   desc "Restart sidekiq service"
#   task :restart do
#     on roles(:worker) do
#       execute :sudo, :systemctl, :restart, fetch(:sidekiq_service_unit_name)
#     end
#   end
# end

# after "deploy:starting", "sidekiq:quiet"
# after "deploy:published", "sidekiq:restart"