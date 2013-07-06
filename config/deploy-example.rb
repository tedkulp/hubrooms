set :stages,        %w{production staging}
set :default_stage, "production"

require 'capistrano/ext/multistage'
require 'capistrano/chef'
require 'airbrake/capistrano'

set :application, "hubrooms"
set :repository,  "git@github.com:tedkulp/hubrooms.git"
set :deploy_to,   "/opt/hubrooms/app"

set :use_sudo, false

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :user, "vagrant"
set :ssh_options, { port: 2222, keys: ["~/.vagrant.d/insecure_private_key"], forward_agent: true }
default_run_options[:pty] = true

set :app_command, "app.coffee"
set :node_binary, "/usr/local/bin/coffee"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

# after "deploy:update_code" do
#     run "ln -nfs #{deploy_to}/#{shared_dir}/default/private #{release_path}/private"
# end

after "deploy:update_code" do
  run "ln -nfs #{deploy_to}/production.json #{release_path}/config/production.json"
end

# namespace :airbrake do
#   desc "Notify Airbrake of a new deploy."
#   task :deploy do
#     system "AIRBRAKE_SERVER=\"errors.tedkulp.com\" node deploy.js #{current_revision} #{repository} #{stage} #{user}"
#   end
# end
