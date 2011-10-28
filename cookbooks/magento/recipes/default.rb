rs_utils_marker :begin

#TODO
#temporary fix. RightScale takes default password from metadata.rb!!!
node.set[:magento][:db][:password] = "magentouser"
node.set[:magento][:admin][:password] = "admin123"

node.set[:magento][:db][:database] = "magentodb"
node.set[:magento][:db][:username] = "magentouser"

r = gem_package "mysql" do
action :nothing
end
r.run_action(:install)


db_host = "10.214.27.127"

remote_recipe "initialize database" do
  recipe "magento::mysql"
  attributes :magento => {
		:db => {
		        :database => node[:magento][:db][:database],
		        :password => node[:magento][:db][:password],
		        :username => node[:magento][:db][:username]
		}
              }
  recipients_tags "database:active=true"
end

package "libmysqlclient-dev"
package "libmysqlclient16"
gem_package "mysql"
require 'rubygems'
Gem.clear_paths
require 'mysql'

ruby_block "check for remote recipe excution to finish" do
  block do
     database_available = false
     timeout = 60 # 5 minutes timeout
     timer = 0
     until database_available or timer > timeout
	     begin
#		m = Mysql.new("#{db_host}", "#{node[:magento][:db][:username]}", "dudi")
		m = Mysql.new("#{db_host}", "#{node[:magento][:db][:username]}", "#{node[:magento][:db][:password]}")
		Chef::Log.info "============================================================================================"
		Chef::Log.info m.list_dbs
		Chef::Log.info "===============================l============================================================="
		database_available = true
	    rescue Mysql::Error => e
		Chef::Log.error "============================================================================================"
		Chef::Log.error "Unable to connect to database: " + e
	#	Chef::Log.error e
	#	Chef::Log.error e.class().toString
		Chef::Log.error "============================================================================================"
		sleep 5;
		timer += 5
	    end
     end
     raise "Database not available. Abort Magento installation." if !database_available
  end
  action :create
end

ruby_block "test" do
  block do
	Chef::Log.info "222============================================================================================"
  end
  action :create
end


if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end

if "webmaster@localhost" == node[:magento][:admin][:email]
  admin_email = "webmaster@#{server_fqdn}"
else
  admin_email = node[:magento][:admin][:email]
end

# Required extensions
%w{php5-cli php5-common php5-curl php5-gd php5-mcrypt php5-mysql php-pear}.each do |package|
  package "#{package}" do
    action :upgrade
  end
end

# Mostly to extend memory_limit which 32Mb on Debian
cookbook_file "/etc/php5/cli/php.ini" do
  source "cli-php.ini"
  mode 0644
  owner "root"
  group "root"
end

log "1--------------------------------------------------------------------------------------------------------"
unless File.exists?("#{node[:magento][:dir]}/installed.flag")
log "2--------------------------------------------------------------------------------------------------------"

  remote_file "#{Chef::Config[:file_cache_path]}/magento-downloader.tar.gz" do
    checksum node[:magento][:downloader][:checksum]
    source node[:magento][:downloader][:url]
    mode "0644"
  end

  directory "#{node[:magento][:dir]}" do
    owner "root"
    group "www-data"
    mode "0755"
    action :create
    recursive true
  end

  bash "magento-download" do
    cwd node[:magento][:dir]
    code <<-EOH
wget http://www.magentocommerce.com/downloads/assets/1.5.1.0/magento-1.5.1.0.tar.gz
tar -zxvf magento-1.5.1.0.tar.gz
chown -R www-data.www-data *
mv magento/* magento/.htaccess .
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod o+w var var/.htaccess app/etc
chmod 550 mage
chmod -R o+w media var
rm -rf magento/ magento-1.5.1.0.tar.gz
EOH
  end
log "3--------------------------------------------------------------------------------------------------------"


#  execute "untar-magento" do
#    cwd node[:magento][:dir]
#    command "tar --strip-components 1 -xzf #{Chef::Config[:file_cache_path]}/magento-downloader.tar.gz"
#  end

#  execute "pear-setup" do
#    cwd node[:magento][:dir]
#    command "./pear mage-setup ."
#  end


#  execute "magento-install-core" do
#    cwd node[:magento][:dir]
#    command "./pear install magento-core/Mage_All_Latest-#{node[:magento][:version]}"
#  end

server_fqdn = ""
log "4--------------------------------------------------------------------------------------------------------"

r = rs_utils_server_collection 'load_balancer' do
  tags [
    "loadbalancer:lb=mylistener"
  ]
  secondary_tags "server:public_ip_0=*"
  action :nothing
end
# get the tags in the compile phase
r.run_action(:load)

if node[:server_collection]['load_balancer'].empty?
  Chef::Log.warn "No load-balancer found."
else
  # 
  next_servers = node[:server_collection]['load_balancer'].to_hash.values.map do |tags|
    [RightScale::Utils::Helper.get_tag_value('server:public_ip_0', tags), tags]
  end.to_hash

  server_ip = nil

  # setup create templates
  next_servers.each do |name, tags|
    log "====================================================================================================="
    server_ip = name
    log name
    log tags
    log "====================================================================================================="
  end

  log server_ip

  Socket.do_not_reverse_lookup = false
  s = Socket.getaddrinfo(server_ip,nil)
  server_fqdn = s[0][2]
end

log "5--------------------------------------------------------------------------------------------------------"

  bash "magento-install-site" do
    cwd node[:magento][:dir]
    code <<-EOH
rm -f app/etc/local.xml
echo php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "#{db_host}" \
--db_name "#{node[:magento][:db][:database]}" \
--db_user "#{node[:magento][:db][:username]}" \
--db_pass "#{node[:magento][:db][:password]}" \
--url "http://#{server_fqdn}/" \
--skip_url_validation \
--use_rewrites "yes" \
--use_secure "yes" \
--secure_base_url "https://#{server_fqdn}/" \
--use_secure_admin "yes" \
--admin_firstname "Admin" \
--admin_lastname "Admin" \
--admin_email "#{admin_email}" \
--admin_username "#{node[:magento][:admin][:user]}" \
--admin_password "#{node[:magento][:admin][:password]}"
php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "#{db_host}" \
--db_name "#{node[:magento][:db][:database]}" \
--db_user "#{node[:magento][:db][:username]}" \
--db_pass "#{node[:magento][:db][:password]}" \
--url "http://#{server_fqdn}/" \
--skip_url_validation \
--use_rewrites "yes" \
--use_secure "yes" \
--secure_base_url "https://#{server_fqdn}/" \
--use_secure_admin "yes" \
--admin_firstname "Admin" \
--admin_lastname "Admin" \
--admin_email "#{admin_email}" \
--admin_username "#{node[:magento][:admin][:user]}" \
--admin_password "#{node[:magento][:admin][:password]}"
touch #{node[:magento][:dir]}/installed.flag
EOH
  end
end
  
log "6--------------------------------------------------------------------------------------------------------"

#This file contains a fix for the SSL Proxy in front
cookbook_file "/var/www/index.php" do
  source "index.php"
  mode 0644
  owner "www-data"
  group "www-data"
end

#template "#{node[:magento][:dir]}/app/etc/local.xml" do      
#  source "local.xml.erb"                                           
#  mode "0600"                                                      
#  owner "root"
#  group "root"
#  variables(:database => node[:magento][:db])
#end
log "7--------------------------------------------------------------------------------------------------------"

rs_utils_marker :end
