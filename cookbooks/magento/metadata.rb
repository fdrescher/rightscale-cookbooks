recipe "magento",                  "Main recipe: Configures PHP, Apache and installs Magento and the Magento example database."
recipe "magento::mysql",           "Create Magento MySQL database and database user."
recipe "magento::install",         "Installs/Reinstalls the core Magento module. Call this recipe only directly after magento::default has been run."
recipe "magento::example-install", "Installs Magento example database and web-assets. Call this recipe only directly after magento::default has been run."


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
  :recipes => [ "magento::default", "magento::install" ]

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
  :recipes => [ "magento::default", "magento::install", "magento::example-install" ]

attribute "magento/db/database",
  :display_name => "Magento MySQL database",
  :description => "Magento will use this MySQL database to store its data.",
  :required => false,
  :default => "magentodb",
  :recipes => [ "magento::default", "magento::install", "magento::example-install", "magento::mysql" ]

attribute "magento/db/username",
  :display_name => "Magento MySQL user",
  :description => "Magento will connect to MySQL using this user.",
  :required => false,
  :default => "magentouser",
  :recipes => [ "magento::default", "magento::install", "magento::example-install", "magento::mysql" ]

attribute "magento/db/password",
  :display_name => "Magento MySQL password",
  :description => "Password for the Magento MySQL user.",
  :required => false,
  :default => "magentouser",
  :recipes => [ "magento::default", "magento::install", "magento::example-install", "magento::mysql" ]

attribute "magento/admin/email",
  :display_name => "Magento Admin email",
  :description => "Email address of the Magento Administrator.",
  :required => false,
  :default => "webmaster@localhost",
  :recipes => [ "magento::default", "magento::install" ]

attribute "magento/admin/user",
  :display_name => "Magento Admin user",
  :description => "User to access Magento Administration panel.",
  :required => false,
  :default => "admin",
  :recipes => [ "magento::default", "magento::install" ]

attribute "magento/admin/password",
  :display_name => "Magento Admin password",
  :description => "Password for the Magento Administration.",
  :required => false,
  :recipes => [ "magento::default", "magento::install" ]

attribute "lb_haproxy/applistener_name",
  :display_name => "Applistener Name",
  :description => "Sets the name of the HAProxy load balance pool on frontends in /home/haproxy/rightscale_lb.cfg. Application severs will join this load balance pool by using this name.  Ex: www",
  :required => true,
  :default => nil,
  :recipes => [ "magento::default", "magento::install" ]

