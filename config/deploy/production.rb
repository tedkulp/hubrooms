set :user, "hubrooms"
set :ssh_options, { forward_agent: true }

chef_role :web, 'roles:web'
chef_role :app, 'roles:web'

set :node_user, "hubrooms"

set :app_command,     'app.coffee'
set :app_environment, 'AIRBRAKE_SERVER="errors.tedkulp.com"'
set :node_binary,     '/usr/local/bin/coffee'
