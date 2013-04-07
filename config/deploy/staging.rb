set :user, "vagrant"
set :ssh_options, { port: 2222, keys: ["~/.vagrant.d/insecure_private_key"], forward_agent: true }

role :web, "localhost"                          # Your HTTP server, Apache/etc
role :app, "localhost"                          # This may be the same as your `Web` server

set :node_user, "vagrant"
