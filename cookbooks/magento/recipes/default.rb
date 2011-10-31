rs_utils_marker :begin

package "mysql-client"

include_recipe "magento::call-mysql"
include_recipe "magento::call-mysql-fix"
include_recipe "magento::php"
include_recipe "magento::apache2"
include_recipe "magento::example-install"
include_recipe "magento::install"

rs_utils_marker :end
