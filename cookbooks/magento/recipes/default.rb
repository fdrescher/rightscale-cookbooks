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

package "mysql-client"


unless File.exists?("#{node[:magento][:dir]}/installed.flag")
  db_host = ""

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

unless File.exists?("#{node[:magento][:dir]}/installed.flag")

  # Download examples
  remote_file "#{Chef::Config[:file_cache_path]}/magento.tar.gz" do
    source node[:magento][:binaries][:url]
    mode "0644"
  end

  directory "#{node[:magento][:dir]}" do
    owner "root"
    group "www-data"
    mode "0755"
    action :create
    recursive true
  end

  bash "Magento install prep" do
    cwd node[:magento][:dir]
    code <<-EOH
    tar -zxvf #{Chef::Config[:file_cache_path]}/magento.tar.gz
    chown -R www-data.www-data *
    mv magento/* magento/.htaccess .
    find . -type f -exec chmod 644 {} \;
    find . -type d -exec chmod 755 {} \;
    chmod o+w var var/.htaccess app/etc
    chmod 550 mage
    chmod -R o+w media var
    rm -rf magento/ magento.tar.gz
    EOH
  end


  r = server_collection 'load_balancer' do
    tags [
      "loadbalancer:lb=mylistener"
    ]
    action :nothing
  end

  # get the tags in the compile phase
  r.run_action(:load)

  if node[:server_collection]['load_balancer'].empty?
    Chef::Log.warn "No load-balancer found."
  else
    # 
    lb_servers = node[:server_collection]['load_balancer'].to_hash.values.map do |tags|
      RightScale::Utils::Helper.get_tag_value('server:public_ip_0', tags)
    end
  
    if lb_servers.length() > 1
      raise "More than one load-balancer found."
    end
  
    lb_host = lb_servers.first()

    Socket.do_not_reverse_lookup = false
    s = Socket.getaddrinfo(lb_host,nil)
    server_fqdn = s[0][2]
  end

  bash "magento-install-site" do
    cwd node[:magento][:dir]
    code <<-EOH
    rm -f app/etc/local.xml
    success=`php -f install.php -- \
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
    --admin_password "#{node[:magento][:admin][:password]}" | grep SUCCESS;echo $?`
    if [[ $success -ne 0 ]]
    then
      exit $success
    fi
    touch #{node[:magento][:dir]}/installed.flag
    EOH
  end
end
  

# This file contains a fix for the SSL Proxy
cookbook_file "/var/www/index.php" do
  source "index.php"
  mode 0644
  owner "www-data"
  group "www-data"
end

rs_utils_marker :end
