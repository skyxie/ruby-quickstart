class ZuoraRubyQuickstart < Sinatra::Base
  register Sinatra::Partial

  enable :sessions
  enable :logging
  enable :partial_underscores

  set :root, File.dirname(__FILE__)
  set :partial_template_engine, :erb

  use Rack::Logger, Logger::DEBUG

  get '/' do
    "Hello World"
  end

  get '/callback' do
    if Zuora::Ruby::PaymentForm.validate(params)
      session['payment_token'] = params["refId"]
      "Payment token #{session['payment_token']} validated!"
    else
      "Payment token invalid!"
    end
  end

  get '/new' do
    @products = ZUORA::Product.all
    @form = Zuora::Ruby::PaymentForm.create(ZUORA_PAYMENT_FORMS[:form_ids][0])
    erb :new
  end

  post '/create' do

    acc = ZUORA::Account.new
    acc.name = params['email']
    acc.status = "Draft"
    acc.paymentTerm = "Due Upon Receipt"
    acc.batch = "Batch1"
    acc.billCycleDay = 1
    acc.autoPay = true
    acc.currency = "USD"
    
    con = ZUORA::Contact.new
    con.firstName = params['first_name']
    con.lastName = params['last_name']
    
    pm = ZUORA::PaymentMethod.new([], session['payment_token'])

    charge = ZUORA::ProductRatePlanCharge.find_by_id(params['product_rate_plan_charge_id'])

    ratePlan = ZUORA::RatePlan.new()
    ratePlan.amendmentType = "NewProduct"
    ratePlan.productRatePlanId = charge.productRatePlanId

    ratePlanCharge = ZUORA::RatePlanCharge.new()
    ratePlanCharge.productRatePlanChargeId = charge.id
    ratePlanCharge.quantity = 1
    ratePlanCharge.triggerEvent = "ServiceActivation"

    ratePlanData = ZUORA::RatePlanData.new
    ratePlanData.ratePlan = ratePlan
    ratePlanData.ratePlanCharge = [ratePlanCharge]

    sub = ZUORA::Subscription.new()
    sub.autoRenew = true
    sub.termType = "EVERGREEN"
    sub.contractEffectiveDate = Time.now
    sub.initialTerm = sub.renewalTerm = charge.term

    subRequest = ZUORA::SubscribeRequest.new
    subRequest.account = acc
    subRequest.billToContact = con
    subRequest.paymentMethod = pm
    subRequest.subscriptionData = ZUORA::SubscriptionData.new(sub, ratePlanData)
    subRequest.subscribeOptions = ZUORA::SubscribeOptions.new(false, false)
    
    subscribes = ZUORA::Subscribe.new
    subscribes << subRequest
    result = Zuora::Ruby::Api.subscribe(subscribes)[0]

    content_type :json
    
    {
      :result => result,
      :account => result.account,
      :subscription => result.subscription,
      :invoice => result.invoice
    }.to_json
  end

end