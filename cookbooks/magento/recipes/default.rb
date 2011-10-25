rs_utils_marker :begin

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

unless File.exists?("#{node[:magento][:dir]}/installed.flag")

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

db_host = node[:magento][:db][:host]
db_host = "10.211.65.175"
server_fqdn = "ec2-50-17-84-33.compute-1.amazonaws.com"
server_fqdn = "dududu.ec2-50-17-84-33.compute-1.amazonaws.com"

r = rs_utils_server_collection 'load_balancer' do
  tags [
    "loadbalancer:app=#{node[:lb_haproxy][:applistener_name]}",
    "loadbalancer:role=master"
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
#  next_servers = node[:server_collection]['load_balancer'].to_hash.values.map do |tags|
#    [RightScale::Utils::Helper.get_tag_value('server:public_ip_0', tags), tags]
#  end.to_hash

  # setup create templates
#  next_servers.each do |name, tags|
#    log "====================================================================================================="
#    log name
#    log tags
#    log "====================================================================================================="
#  end
end


  bash "magento-install-site" do
    cwd node[:magento][:dir]
    code <<-EOH
rm -f app/etc/local.xml
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
  
#This file contains a fix for the SSL Proxy in front
cookbook_file "/var/www/index.php" do
  source "index.php"
  mode 0644
  owner "www-data"
  group "www-data"
end

template "#{node[:magento][:dir]}/app/etc/local.xml" do      
  source "local.xml.erb"                                           
  mode "0600"                                                      
  owner "root"
  group "root"
  variables(:database => node[:magento][:db])
end

rs_utils_marker :end
