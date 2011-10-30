## This recipe is not intended to be called directly

rs_utils_marker :begin

# prerequisite for mysql gem
p = package "libmysqlclient-dev" do
  action :nothing
end
p.run_action(:install)

# prerequisite for mysql gem
p = package "libmysqlclient16" do
  action :nothing
end
p.run_action(:install)

p = gem_package "mysql" do
  action :nothing
end
p.run_action(:install)




db_host = ""

r = server_collection 'database' do
  tags [
    "database:active=true"
  ]
  action :nothing
end
  
# get the tags in the compile phase
r.run_action(:load)

if node[:server_collection]['database'].empty?
  raise "No database found."
else
  # 
  database_servers = node[:server_collection]['database'].to_hash.values.map do |tags|
    RightScale::Utils::Helper.get_tag_value('server:private_ip_0', tags)
  end
  
  if database_servers.length() > 1
    raise "More than one database found."
  end
  db_host = database_servers.first()
end


require 'rubygems'
Gem.clear_paths
require 'mysql'

ruby_block "check for remote recipe excution to finish" do
  block do
    database_available = false
    timeout = 600 # 10 minutes timeout
    timer = 0
    Chef::Log.info "Checking if database is initialized: #{db_host}"
    until database_available or timer > timeout
      begin
        m = Mysql.new("#{db_host}", "#{node[:magento][:db][:username]}", "#{node[:magento][:db][:password]}")
        if m.list_dbs.include?(node[:magento][:db][:database])
          database_available = true
        else
          Chef::Log.warn "Waiting for Magento database to get created. Retrying: (" + timer.to_s + "s/" + timeout.to_s + "s)"
        end
      rescue Mysql::Error => e
        Chef::Log.error "Unable to connect to database: " + e + ". Retrying: (" + timer.to_s + "s/" + timeout.to_s + "s)"
      end
      sleep 5;
      timer += 5
    end
    raise "Database not available. Abort Magento installation." if !database_available
  end
  action :create
end

rs_utils_marker :end
