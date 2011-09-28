maintainer       "YOUR_COMPANY_NAME"
maintainer_email "YOUR_EMAIL"
license          "All rights reserved"
description      "Installs/Configures my-first-cookbook"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"
recipe "my-first-cookbook::helloworld", "My first recipe, prints Hello World to the RightScale dashboard"
recipe "my-first-cookbook::hello", "My second recipe, prints Hello NAME to the RightScale dashboard"

attribute "name",
:display_name => "Test value",
:description => "Test specifying Input via Chef attribute",
:required => true,
:recipes => [ "my-first-cookbook::hello" ]

