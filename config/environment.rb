require "sinatra"
require "sinatra/partial"
require "json"
require "yaml"
require "zuora-ruby"
require "zuora_ruby_quickstart"

ZUORA_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "credentials.yml"))
ZUORA_PAYMENT_FORMS = YAML.load_file(File.join(File.dirname(__FILE__), "payment_forms.yml"))

Zuora::Ruby::Api.login(ZUORA_CONFIG[:username], ZUORA_CONFIG[:password])

Zuora::Ruby::PaymentForm.tenant_id = ZUORA_PAYMENT_FORMS[:tenant_id]
Zuora::Ruby::PaymentForm.api_security_key = ZUORA_PAYMENT_FORMS[:api_security_key]
