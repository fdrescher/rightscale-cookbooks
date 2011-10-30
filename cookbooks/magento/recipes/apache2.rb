rs_utils_marker :begin

node.set[:apache][:listen_ports] = [ "80","443","8000" ]

#service "apache2" do
#  action :nothing
#end

include_recipe %w{magento}

web_app "magento" do
  template "apache-site.conf.erb"
  docroot "#{node[:magento][:dir]}"
end

rs_utils_marker :end

