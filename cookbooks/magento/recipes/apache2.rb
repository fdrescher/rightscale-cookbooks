rs_utils_marker :begin

node.set[:apache][:listen_ports] = [ "80","443","8000" ]

web_app "magento" do
  template "apache-site.conf.erb"
  docroot "#{node[:magento][:dir]}"
end

rs_utils_marker :end
