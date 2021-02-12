set :stage, 'production'
set :rails_env, :production
# set :enable_by_each_restart, -> { true }

# set :exclude_elb_restart, -> { [] }
# set :aws_instances_tags, -> { { 'env': 'staging', 'app': 'tournity' } }
# set :aws_target_group_arns, -> { [
#   'arn:aws:elasticloadbalancing:us-east-1:020708677223:targetgroup/web-staging/82d7ca8ca13fa34e'
# ] }

set :branch, ENV['BRANCH'] || "master"

server '65.0.182.115', port: 22, roles: %w{app web db worker}, primary: true
# server '3.229.222.195', port: 22, roles: %w{app worker}
