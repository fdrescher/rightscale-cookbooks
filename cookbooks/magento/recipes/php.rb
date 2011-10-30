## This recipe is not intended to be called directly

rs_utils_marker :begin

# Required extensions
%w{php5-cli php5-common php5-curl php5-gd php5-mcrypt php5-mysql php-pear}.each do |package|
  package "#{package}" do
    action :install
  end
end

# Mostly to extend memory_limit which 32Mb on Debian
cookbook_file "/etc/php5/cli/php.ini" do
  source "cli-php.ini"
  mode 0644
  owner "root"
  group "root"
end

rs_utils_marker :end
