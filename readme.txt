Zuora Ruby Quickstart

INTRODUCTION
------------

Thank you for downloading the Zuora Ruby QuickStart.  This download contains code 
designed to help you begin using Zuora APIs.

REQUIREMENTS
------------

The following needs to be installed for the example:

- Ruby 2.3.2 (install using "gem install -v=2.3.2 rails")
- soap4r (install using "gem install soap4r")

Note: the files included in this Quickstart include source that was originally generated 
using soap4r. They have been modified to work with the Zuora API. 

If you choose to generate source from the WSDL, please make sure to incorporate the 
following manual changes to the code: 

- ZUORA.rb - Added SessionHeader.on_outbound_headeritem() to support headers

CONTENTS
--------

This zip follows the Ruby directory structure convention, but contains the minimum set 
for a basic console application.

    /app/controllers/* - Controllers for example
    /app/views/* - Views for example
    /config/environment.rb - default environment settings, which includes 
        - adding zuora libraries to lib path (and loading)
        - disabling Active Record (no database)
        - default Zuora username/password parameters
        - overriding HandlerSet to allow setting of headers
    /lib/* - Zuora API interface code
    /readme.txt - this file
    /zuora.17.0.wsdl - version 17.0 of the zuora WSDL

For more information on the directory structure, see: 

    http://www.tutorialspoint.com/ruby-on-rails/rails-directory-structure.htm

DOCUMENTATION & SUPPORT
-----------------------

API Documentation is available at http://developer.zuora.com

PRE-REQUISITES
--------------

The following are pre-requisites to successfully run the sample code:

1. A Zuora Tenant
2. A Zuora User
    a.) with the User Role Permission to create Invoices 
        (http://knowledgecenter.zuora.com/index.php/Z-Billing_Admin#Manage_User_Roles)
3. A Product created with a Rate Plan & Rate Plan Component 
        (http://knowledgecenter.zuora.com/index.php/Product_Catalog), with
    a.) The Effective Period (Start & End) of the Product/Rate Plan not expired 
        (start < today and end > today)
    b.) An Accounting Code specified on the Rate Plan Component 
4. A Zuora Gateway set up 
   (http://knowledgecenter.zuora.com/index.php/Z-Payments_Admin#Setup_Payment_Gateway)
    a.) Either Authorize.net, CyberSource, PayPal Payflow Pro (production or test)
    b.) The setting "Verify new credit card" disabled

SETTING UP YOUR ENVIRONMENT
--------------------------

The overall goal is to set up a default ruby environment and copy the Zuora-specific files 
into it. 

1. On the command line, type "rails ruby-quickstart"
2. Unzip the files contained in the quickstart_ruby.zip file to that directory, copying 
files over existing files where necessary. Note: this will also overwrite environment.rb.
If you are integrating with an existing system, note the changes and incorporate them 
manually.
3. In /config/environment.rb, set ZUORA_USER and ZUORA_PASSWORD to your username/password.

RUNNING THE SIGNUP EXAMPLE
--------------------------

Once the environment is set up, you only need to start the Ruby server.

1. From the root of the directory, type "ruby script/server"
2. Open a browser and go to http://localhost:3000/signup/action

RUNNING THE COMMAND-LINE EXAMPLE
--------------------------------

1. From the root of the directory, type "ruby script/console"
2. In the command line, you will see the >> prompt. Do the following to execute the set of tests:

    >> t = ZuoraInterface.new
    >> t.run_tests


