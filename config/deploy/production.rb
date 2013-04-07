set :user, "hubrooms"
set :ssh_options, { forward_agent: true }

chef_role :web, 'roles:web'
chef_role :app, 'roles:web'

set :node_user, "hubrooms"
