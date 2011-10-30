rs_utils_marker :begin

node.set[:apache][:listen_ports] = [ "80","443","8000" ]

service "apache2" do
#  case node[:platform]
#  when "centos","redhat","fedora","suse"
#    service_name "httpd"
#    # If restarted/reloaded too quickly httpd has a habit of failing.
#    # This may happen with multiple recipes notifying apache to restart - like
#    # during the initial bootstrap.
#    restart_command "/sbin/service httpd restart && sleep 1"
#    reload_command "/sbin/service httpd reload && sleep 1"
#  when "debian","ubuntu"
#    service_name "apache2"
#  end
#  supports value_for_platform(
#    "debian" => { "4.0" => [ :restart, :reload ], "default" => [ :restart, :reload, :status ] },
#    "ubuntu" => { "default" => [ :restart, :reload, :status ] },
#    "centos" => { "default" => [ :restart, :reload, :status ] },
#    "redhat" => { "default" => [ :restart, :reload, :status ] },
#    "fedora" => { "default" => [ :restart, :reload, :status ] },
#    "default" => { "default" => [:restart, :reload ] }
#  )
  action :nothing
end

include_recipe %w{magento}

if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end

web_app "magento" do
  template "apache-site.conf.erb"
  docroot "#{node[:magento][:dir]}"
end

#%w{default 000-default}.each do |site|
#  apache_site "#{site}" do
#    enable false
#  end
#end

#execute "ensure correct permissions" do
#  command "chown -R root:#{node[:apache][:user]} #{node[:magento][:dir]} && chmod -R g+rw #{node[:magento][:dir]}"
#  action :run
#end
#log "33--------------------------------------------------------------------------------------------------------"
#include_recipe %w{apache2::mod_ssl}
#log "44--------------------------------------------------------------------------------------------------------"

rs_utils_marker :end

