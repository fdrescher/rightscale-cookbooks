## This recipe is not intended to be called directly

rs_utils_marker :begin

unless File.exists?("#{node[:magento][:dir]}/installed.flag") # this flag is set after a successfull Magento installation

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

end

rs_utils_marker :end
