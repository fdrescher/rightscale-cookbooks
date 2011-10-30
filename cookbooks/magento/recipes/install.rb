## This recipe is not intended to be called directly

rs_utils_marker :begin

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

  if "webmaster@localhost" == node[:magento][:admin][:email]
    admin_email = "webmaster@#{server_fqdn}"
  else
    admin_email = node[:magento][:admin][:email]
  end

  include_recipe "magento::get-load-balancer-fqdn" ##returns: server_fqdn

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
