Simple sinatra web server to make purchases to the zuora SOAP api. Uses the skyxie/zuora-ruby library to structure requests and parse responses. Requires authentication for the zuora sandbox to get started.

This server uses bundler to handle ruby gem requirements. To install all requirements:

    gem install bundler
    bundle install

Start web server:

    bundle exec rackup -p <port>
