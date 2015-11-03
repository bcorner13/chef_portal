# Cookbook Name:: chef_portal
# Recipe:: provisioner_node

portal_user = node['chef_portal']['user']
portal_pass = node['chef_portal']['password'].crypt('$6$' + rand(36**8).to_s(36))

# Setup the portal user
user portal_user do
  comment 'Chef Portal User'
  shell '/bin/bash'
  password portal_pass
end

# Give non-root users sudo
# sudo portal_user do
#   user portal_user
#   nopasswd true
#   defaults ['!requiretty']
# end

# enable password login
service 'sshd' do
  action :nothing
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[sshd]', :immediately
end

# install explicitly pinned ChefDK
chef_dk 'Install ChefDK' do
  version node['chef_portal']['chefdk']['version']
  global_shell_init true
end

template '/root/.bashrc' do
  source 'bashrc.erb'
  mode '0640'
end

# install packages
package node['chef_portal']['pkgs'] do
  action :install
end

# install gems if present
node['chef_portal']['chefdk']['gems'].each do |gem, ver|
  gem_package gem do
    gem_binary '/opt/chefdk/embedded/bin/gem'
    version ver
  end
end

# get my AWS creds from IAM
include_recipe 'chef_portal::_refresh_iam_creds'
