rs_utils_marker :begin

remote_file "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz" do
#  checksum node[:magento][:downloader][:checksum]
  source "http://www.magentocommerce.com/downloads/assets/1.1.2/magento-sample-data-1.1.2.tar.gz"
#  source node[:magento][:downloader][:url]
  mode "0644"
end

log "----------------------------------------------------------------------------------------------------------"
log "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz"
log "----------------------------------------------------------------------------------------------------------"


directory "#{node[:magento][:dir]}" do
  owner "root"
  group "www-data"
  mode "0755"
  action :create
  recursive true
end

#bash "magento-download" do
#  cwd node[:magento][:dir]
#  code <<-EOH
#  mv "#{Chef::Config[:file_cache_path]}/magento-sample-data.tar.gz"/media/* magento/media/
#  chmod -R o+w media
#  EOH
#end

rs_utils_marker :end
