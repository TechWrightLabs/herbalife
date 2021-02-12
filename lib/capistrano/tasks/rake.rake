namespace :rake do  
  desc "Run a task on a remote server."  
  # run like: cap staging rake:invoke task=a_certain_task  
  task :invoke do
    puts "Running task: #{ENV['TASK']}, environment: #{fetch(:stage)}"
    run("cd #{deploy_to}/current; /usr/bin/env rake #{ENV['TASK']} RAILS_ENV=#{fetch(:stage)}")  
  end  
end