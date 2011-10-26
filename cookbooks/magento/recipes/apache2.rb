rs_utils_marker :begin

node.set[:apache][:listen_ports] = [ "80","443","8000" ]

service "apache2" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    service_name "httpd"
    # If restarted/reloaded too quickly httpd has a habit of failing.
    # This may happen with multiple recipes notifying apache to restart - like
    # during the initial bootstrap.
    restart_command "/sbin/service httpd restart && sleep 1"
    reload_command "/sbin/service httpd reload && sleep 1"
  when "debian","ubuntu"
    service_name "apache2"
  end
  supports value_for_platform(
    "debian" => { "4.0" => [ :restart, :reload ], "default" => [ :restart, :reload, :status ] },
    "ubuntu" => { "default" => [ :restart, :reload, :status ] },
    "centos" => { "default" => [ :restart, :reload, :status ] },
    "redhat" => { "default" => [ :restart, :reload, :status ] },
    "fedora" => { "default" => [ :restart, :reload, :status ] },
    "default" => { "default" => [:restart, :reload ] }
  )
  action :nothing
end

#modified for RightScale
include_recipe %w{magento}
#include_recipe %w{magento apache2 apache2::mod_deflate apache2::mod_expires apache2::mod_headers apache2::mod_rewrite apache2::mod_ssl apache2::mod_php5}

if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end

bash "Create SSL Certificates" do
  cwd "#{node[:apache][:dir]}/ssl"
  code <<-EOH
  umask 022
  openssl genrsa 2048 > #{server_fqdn}.key
  openssl req -batch -new -x509 -days 365 -key #{server_fqdn}.key -out #{server_fqdn}.crt
  cat #{server_fqdn}.crt #{server_fqdn}.key > #{server_fqdn}.pem
  EOH
  only_if { File.zero?("#{node[:apache][:dir]}/ssl/#{server_fqdn}.pem") }
  action :nothing
end

cookbook_file "#{node[:apache][:dir]}/ssl/#{server_fqdn}.pem" do
  source "cert.pem"
  mode 0644
  owner "root"
  group "root"
  notifies :run, resources(:bash => "Create SSL Certificates"), :immediately
end
log "11--------------------------------------------------------------------------------------------------------"
%w{magento magento_ssl}.each do |site|
  web_app "#{site}" do
    template "apache-site.conf.erb"
    docroot "#{node[:magento][:dir]}"
    server_name server_fqdn
    server_aliases node.fqdn
    ssl (site == "magento_ssl")?true:false
  end
end
log "22--------------------------------------------------------------------------------------------------------"
%w{default 000-default}.each do |site|
  apache_site "#{site}" do
    enable false
  end
end

execute "ensure correct permissions" do
  command "chown -R root:#{node[:apache][:user]} #{node[:magento][:dir]} && chmod -R g+rw #{node[:magento][:dir]}"
  action :run
end
log "33--------------------------------------------------------------------------------------------------------"
include_recipe %w{apache2::mod_ssl}
log "44--------------------------------------------------------------------------------------------------------"

rs_utils_marker :end

