rs_utils_marker :begin

require 'rubygems'
Gem.clear_paths
require 'mysql'

execute "Install MySQL Magento privileges" do
  command "/usr/bin/mysql -u root < /etc/magento-grants.sql"  #no -p (password): the RightScale MySQL installation does not have a password
  action :nothing
end

template "/etc/magento-grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(:database => node[:magento][:db])
  notifies :run, resources(:execute => "Install MySQL Magento privileges"), :delayed
end

execute "Only called if used as remote_recipe" do
  command "echo \"remote recipe execution\""
  not_if node[:remote_recipe].nil?  
  notifies :run, resources(:execute => "Install MySQL Magento privileges"), :delayed
end

execute "create #{node[:magento][:db][:database]} database" do
  command "/usr/bin/mysqladmin -u root create #{node[:magento][:db][:database]}" #no -p (password)
  not_if do
    m = Mysql.new("localhost", "root", "") #no (password)
    m.list_dbs.include?(node[:magento][:db][:database])
  end
end

rs_utils_marker :end
