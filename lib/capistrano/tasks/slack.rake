# require 'slackistrano/capistrano'
# require_relative '../../custom_messaging'

# # frozen_string_literal: true
# set :slack_url, 'https://hooks.slack.com/services/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'
# set :slack_channel, '#medici-deploy'
# set :slack_username, 'bumblebee'
# set :slack_emoji, ':shipit:'
# set :slack_deploy_user, -> {`git config user.name`.to_s.tr("\n", '')}
# set :slack_deploy_email, -> {`git config user.email`.to_s.tr("\n", '')}


# set :slackistrano, {
#   klass: Slackistrano::CustomMessaging,
#   channel: '#medici-deploy',
#   webhook: 'https://hooks.slack.com/services/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',
#   icon_emoji: ':ship:',
#   username: 'bumblebee'
# }

# after 'deploy:failed', 'slack:deploy:failed'
# before 'deploy:starting', 'slack:deploy:updating'
# after 'deploy:finishing', 'slack:deploy:updated'
# before 'deploy:reverting', 'slack:deploy:failed'