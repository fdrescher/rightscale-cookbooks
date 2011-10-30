## This recipe is not intended to be called directly

rs_utils_marker :begin

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

rs_utils_marker :end
