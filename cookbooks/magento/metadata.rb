recipe           "magento", "Install magento"
recipe           "magento::mysql", "Create mysql database for magento"
recipe           "magento::sample_data", "Pre-populate magento with sample data"
recipe           "magento::apache2", "Install apache2 webserver for magento"
recipe           "magento::nginx", "Install nginx webserver for magento"
recipe           "magento::example-install", "Installs Magento example database and web-assets"


%w{ debian ubuntu }.each do |os|
  supports os
end

%w{ apache2 mysql }.each do |cb|
  depends cb
end

depends "rs_tools"
depends "rs_utils"

attribute "magento/binaries/url",
  :display_name => "Magento binaries URL",
  :description => "URL to magento binaries.",
  :required => false,
  :default => "http://www.magentocommerce.com/downloads/assets/1.5.1.0/magento-1.5.1.0.tar.gz",
  :recipes => [ "magento::default" ]

attribute "magento/examples/url",
  :display_name => "Magento example URL",
  :description => "URL to magento examples.",
  :required => false,
  :default => "http://www.magentocommerce.com/downloads/assets/1.1.2/magento-sample-data-1.1.2.tar.gz",
  :recipes => [ "magento::example-install" ]

attribute "magento/dir",
  :display_name => "Magento installation directory",
  :description => "Location to place magento files.",
  :required => false,
  :default => "/var/www",
  :recipes => [ "magento::default", "magento::example-install" ]

attribute "magento/db/database",
  :display_name => "Magento MySQL database",
  :description => "Magento will use this MySQL database to store its data.",
  :required => false,
  :default => "magentodb"

attribute "magento/db/user",
  :display_name => "Magento MySQL user",
  :description => "Magento will connect to MySQL using this user.",
  :required => false,
  :default => "magentouser"

attribute "magento/db/password",
  :display_name => "Magento MySQL password",
  :description => "Password for the Magento MySQL user.",
  :required => true

attribute "magento/admin/email",
  :display_name => "Magento Admin email",
  :description => "Email address of the Magento Administrator.",
  :required => false,
  :default => "webmaster@localhost",
  :recipes => [ "magento::default" ]

attribute "magento/admin/user",
  :display_name => "Magento Admin user",
  :description => "User to access Magento Administration panel.",
  :required => false,
  :default => "admin",
  :recipes => [ "magento::default" ]


attribute "magento/admin/password",
  :display_name => "Magento Admin password",
  :description => "Password for the Magento Administration.",
  :required => true,
  :recipes => [ "magento::default" ]

#TEST
attribute "magento/test/test",
  :display_name => "Test attribute",
  :description => "Test attribute.",
  :required => false,
  :default => "lalala"

