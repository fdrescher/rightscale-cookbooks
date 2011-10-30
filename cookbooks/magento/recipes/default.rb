rs_utils_marker :begin

package "mysql-client"


unless File.exists?("#{node[:magento][:dir]}/installed.flag") # this flag is set after a successfull Magento installation

  include_recipe "magento::call-mysql"

  include_recipe "magento::call-mysql-fix"
end

#if node.has_key?("ec2")
#  server_fqdn = node.ec2.public_hostname
#else
#  server_fqdn = node.fqdn
#end

include_recipe "magento::php"
include_recipe "magento::install"

rs_utils_marker :end
