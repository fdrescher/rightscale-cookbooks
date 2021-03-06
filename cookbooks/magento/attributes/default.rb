default[:magento][:binaries][:url] = "http://www.magentocommerce.com/downloads/assets/1.5.1.0/magento-1.5.1.0.tar.gz"
default[:magento][:examples][:url] = "http://www.magentocommerce.com/downloads/assets/1.1.2/magento-sample-data-1.1.2.tar.gz"
default[:magento][:dir] = "/var/www"
default[:magento][:db][:host] = "localhost"
default[:magento][:db][:database] = "magentodb"
default[:magento][:db][:username] = "magentouser"
default[:magento][:db][:password] = "magentouser"
default[:magento][:admin][:email] = "webmaster@localhost"
default[:magento][:admin][:user] = "admin"
default[:magento][:admin][:password] = "admin123" # Important: Magento has some restrictions on the password (length, numbers)

