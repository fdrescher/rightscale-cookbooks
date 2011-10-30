rs_utils_marker :begin

# Uses the chef temporary path (/var/cache/rightscale/) for storing temporary files
directory "#{Chef::Config[:file_cache_path]}/tmp" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

# Download examples
remote_file "#{Chef::Config[:file_cache_path]}/tmp/magento-sample-data.tar.gz" do
  source node[:magento][:examples][:url]
  mode "0644"
end

# Make sure example directory exists
directory "#{node[:magento][:dir]}/media" do
  owner "root"
  group "www-data"
  mode "0755"
  action :create
  recursive true
end

# Copy web-assets to Magento directory
bash "install example files" do
  cwd node[:magento][:dir]
  code <<-EOH
  tar -xvf "#{Chef::Config[:file_cache_path]}"/tmp/magento-sample-data.tar.gz -C "#{Chef::Config[:file_cache_path]}"/tmp
  mv "#{Chef::Config[:file_cache_path]}"/tmp/magento-sample-data*/media/* media/
  chmod -R o+w media
  EOH
end

package "mysql-client"

# Find database server
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

# Re-create Magento database
# Caution: The existing database will be deleted.
bash "install example database" do
  cwd "#{Chef::Config[:file_cache_path]}"+"/tmp"
  code <<-EOH
  mysql -h"#{db_host}" -u"#{node[:magento][:db][:username]}" -p"#{node[:magento][:db][:password]}" -e \"drop database "#{node[:magento][:db][:database]}"\"
  mysql -h"#{db_host}" -u"#{node[:magento][:db][:username]}" -p"#{node[:magento][:db][:password]}" -e \"create database "#{node[:magento][:db][:database]}"\"
  mysql -h"#{db_host}" -u"#{node[:magento][:db][:username]}" -p"#{node[:magento][:db][:password]}" "#{node[:magento][:db][:database]}" < "#{Chef::Config[:file_cache_path]}"/tmp/magento-sample-data*/magento_sample_data*.sql
  EOH
end

rs_utils_marker :end
