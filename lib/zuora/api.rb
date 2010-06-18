require 'singleton'

module Zuora
  module Billing
    class Api
      include Singleton
      def initialize
        @driver = ZUORA::Soap.new
      end
      
      attr_reader :driver
    end
  end
end