require 'zuora/api.rb'
class ZuoraExperimental
  include Validatable
  
  attr_accessor :fee, 
                :sage_confirmation, 
                :approval_error, 
                :cc_number, 
                :cc_expire, 
                :cc_cvv, 
                :first_name, 
                :last_name, 
                :address, 
                :city, 
                :state, 
                :zip, 
                :email, 
                :ach_bank_name, 
                :ach_route, 
                :ach_account, 
                :ach_acct_type, 
                :transaction_type, 
                :registered_nonprofit_id, 
                :registered_nonprofit_object, 
                :owner_first_name, 
                :owner_last_name, 
                :owner_email, 
                :time_zone, 
                :suffix, 
                :product,
                :package_item_ids

  validates_presence_of :cc_number, :if => Proc.new {|cb| cb.transaction_type == "cc"}
  validates_presence_of :cc_expire, :if => Proc.new {|cb| cb.transaction_type == "cc"}
  validates_presence_of :cc_cvv, :if => Proc.new {|cb| cb.transaction_type == "cc"}
  validates_presence_of :ach_bank_name, :if => Proc.new {|cb| cb.transaction_type == "ach"}
  validates_presence_of :ach_route, :if => Proc.new {|cb| cb.transaction_type == "ach"}
  validates_presence_of :ach_account, :if => Proc.new {|cb| cb.transaction_type == "ach"}
  validates_presence_of :ach_acct_type, :if => Proc.new {|cb| cb.transaction_type == "ach"}

  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :address
  validates_presence_of :city
  validates_presence_of :state
  validates_presence_of :zip
  validates_presence_of :email
  validates_presence_of :registered_nonprofit_id
  
  def initialize(params={})
    params = {} if params.blank?
    if params
      params.each do |key,value|
        send(key.to_s + '=', value)
      end
    end
  end
  
  def self.accessors 
    [:sage_confirmation, 
     :approval_error, 
     :cc_number, 
     :cc_expire, 
     :cc_cvv, 
     :first_name, 
     :last_name, 
     :address, 
     :city, 
     :state, 
     :zip, 
     :email, 
     :ach_bank_name, 
     :ach_route, 
     :ach_account, 
     :ach_acct_type, 
     :transaction_type, 
     :registered_nonprofit_id,
     :package_item_ids]
  end
  
  def cc?
    self.transaction_type == "cc"
  end
  
  def ach?
    self.transaction_type == "ach"
  end
  
  def registered_nonprofit
    self.registered_nonprofit_object ||= RegisteredNonprofit.find(registered_nonprofit_id)
  end
  
  def registered_nonprofit_owner_first_name
    self.owner_first_name ||= registered_nonprofit.owner.first_name
  end
  
  def registered_nonprofit_owner_last_name
    self.owner_last_name ||= registered_nonprofit.owner.last_name
  end
  
  def registered_nonprofit_owner_email
    self.owner_email ||= registered_nonprofit.owner.email
  end
  
  def id_suffix
    self.suffix ||= get_suffix
  end
  
  def subscription_level
    registered_nonprofit.plan_item.product
  end
  
  def billing_type
    registered_nonprofit.plan_item.plan
  end
  
  def package_items
    @package_items ||= registered_nonprofit.package_item_objects
  end
  
  def time_zone_by_zip
    if self.time_zone.blank?
      if zip = ZipCode.find(:first, :conditions => ["zip =?", registered_nonprofit.zip.to_s[0...5]])
        self.time_zone = zip.time_zone
      else
        self.time_zone = 0
      end
    end
    self.time_zone
  end
  
  def update_attributes(_attributes={})
    CustomerBilling.accessors.each { |attribute| eval("self.#{attribute} = _attributes[attribute] unless _attributes[attribute].nil?") }
  end
  
  def to_attributes
    {:first_name => self.first_name, 
     :last_name => self.last_name, 
     :address => self.address, 
     :city => self.city, 
     :state => self.state, 
     :zip => self.zip, 
     :email => self.email, 
     :transaction_type => self.transaction_type,
     :registered_nonprofit_id => self.registered_nonprofit_id,
     :ach_bank_name => self.ach_bank_name,
     :ach_route => self.ach_route,
     :ach_account => self.ach_account,
     :ach_acct_type => self.ach_acct_type,
     :fee => self.fee,
     :owner_first_name => registered_nonprofit.owner.first_name,
     :owner_last_name => registered_nonprofit.owner.last_name,
     :owner_email => registered_nonprofit.owner.email,
     :time_zone => time_zone_by_zip,
     :suffix => id_suffix,
     :product => self.product,
     :package_item_ids => self.package_item_ids}
  end
  
  def zuora_lookup(query)
    q = ZUORA::Query.new
    q.queryString = query
    results = @z.query(q)
    return results
  end
  
  def get_zuora_object(query)
    object = zuora_lookup(query)
    unless object.result.size == 0
      return object.result.records.first  
    else
      return nil
    end
  end
  
  def get_zuora_object_array(query)
    object = zuora_lookup(query)
    unless object.result.size == 0
      return object.result.records
    else
      return []
    end
  end
  
  def get_zuora_driver
    @z ||= Zuora::Billing::Api.instance.driver
  end
  
  def zuora_driver
    get_zuora_driver
  end
  
  def zuora_login
    loginargs = ZUORA::Login.new
    loginargs.username = "username" #ZUORA_USER
    loginargs.password = "password" #ZUORA_PASSWORD
    @zuora_session = ZUORA::SessionHeader.new
    @zuora_session.session = @z.login(loginargs).result.session
  end
  
  def zuora_session_prep
    get_zuora_driver
    zuora_session_cleanup
    zuora_login
    @z.headerhandler.set @zuora_session
    @z.wiredump_dev = STDERR
  end
  
  def zuora_session_cleanup
    @z.headerhandler.delete(@zuora_session) if @zuora_session
  end
  
  ###########################################################################################
  #                                  Zuora Account Methods                                  #
  ###########################################################################################
  
  def update_crm_id(crm_id)
    zuora_session_prep
    account = get_zuora_object("SELECT Id, SoldToId, BillToId, DefaultPaymentMethodId, Status FROM Account WHERE AccountNumber = '#{registered_nonprofit_id}#{id_suffix}'")
    acc_obj = ZUORA::Account.new
    acc_obj.id = account.id
    acc_obj.crmId = crm_id
    @z.update([acc_obj])
    zuora_session_cleanup
  end
  
  def create_zuora_account
    val = false
    zuora_session_prep
    account = @z.create([zuora_account])
    puts account.first.inspect
    if account.first.success
      payment = @z.create([zuora_payment_method(account.first.id)])
      payment.first.success ? val = true : add_zuora_errors(payment)
    else
      add_zuora_errors(account)
    end
    zuora_session_cleanup
    return val
  end
  
  def update_zuora_account
    account = get_zuora_object("SELECT Id, SoldToId, BillToId, DefaultPaymentMethodId, Status FROM Account WHERE AccountNumber = '#{registered_nonprofit_id}#{id_suffix}'")
    payment_method = get_zuora_object("SELECT Id FROM PaymentMethod WHERE AccountId = '#{account.id}'")
    bill_to = account.billToId.blank? ? zuora_bill_to_contact(account.id) : nil
    sold_to = account.soldToId.blank? ? zuora_sold_to_contact(account.id) : nil
    contact_results = @z.create([bill_to, sold_to]) unless bill_to.blank? && sold_to.blank?
  
    if account.status != "Active" || account.soldToId.blank? || account.billToId.blank? || account.defaultPaymentMethodId.blank?
      acc_obj = ZUORA::Account.new
      acc_obj.id = account.id
      acc_obj.autoPay = 1
      acc_obj.soldToId = contact_results.first.id if account.soldToId.blank?
      acc_obj.billToId = contact_results.last.id if account.billToId.blank?
      acc_obj.defaultPaymentMethodId = payment_method.id if account.defaultPaymentMethodId.blank?
      acc_obj.status = "Active" unless account.status == "Active"
      @z.update([acc_obj])
    end
    account.id
  end
  
  def zuora_account
    acc = ZUORA::Account.new
    acc.accountNumber = "#{registered_nonprofit_id}#{id_suffix}"
    acc.allowInvoiceEdit = 0
    acc.name = get_unique_name(registered_nonprofit.name, registered_nonprofit.id)
    acc.currency = "USD"
    acc.autoPay = 0
    acc.status = "Draft"
    acc.paymentTerm = "Due Upon Receipt"
    acc.batch = cc? ? "Batch1" : "Batch2"
    acc.billCycleDay = ["29","30","31"].include?(day) ? "01" : day # numeric day of anniversary
    return acc
  end
  
  def zuora_bill_to_contact(account=nil)
    con = ZUORA::Contact.new
    con.accountId = account unless account.blank?
    con.address1 = address || registered_nonprofit.bill_to.address1
    con.city = city || registered_nonprofit.bill_to.city
    con.state = state || registered_nonprofit.bill_to.state
    con.postalCode = zip || registered_nonprofit.bill_to.zip
    con.country = "United States"
    con.firstName = first_name || registered_nonprofit.bill_to.first_name
    con.lastName = last_name || registered_nonprofit.bill_to.last_name
    con.workEmail = email || registered_nonprofit.bill_to.email
    return con
  end
  
  def create_bill_to
    bill_to = Contact.new(:first_name => first_name, :last_name => last_name, :email => email, :address1 => address, :city => city, :state => state, :zip => zip, :parent_id => registered_nonprofit_id, :parent_type => "RegisteredNonprofit")
    if bill_to.save
      return bill_to.id
    else
      return nil
    end
  end
  
  def zuora_sold_to_contact(account=nil)
    con = ZUORA::Contact.new
    con.accountId = account unless account.blank?
    con.address1 = registered_nonprofit.address1
    con.city = registered_nonprofit.city
    con.state = US_STATES[registered_nonprofit.state]
    con.postalCode = registered_nonprofit.zip
    con.country = "United States"
    con.firstName = registered_nonprofit_owner_first_name
    con.lastName = registered_nonprofit_owner_last_name
    con.workEmail = registered_nonprofit_owner_email
    return con
  end
  
  def zuora_payment_method(account=nil)
    pmt = ZUORA::PaymentMethod.new
    pmt.accountId = account unless account.blank?
    if cc?
      pmt.creditCardAddress1 = address
      pmt.creditCardCity = city
      pmt.creditCardState = state
      pmt.creditCardPostalCode = zip
      pmt.creditCardCountry = "United States"
      pmt.creditCardExpirationMonth = cc_expire[0..1] # 2 digit month, int?
      pmt.creditCardExpirationYear = "20" + cc_expire[2..3] # 4 digit year, int
      pmt.creditCardHolderName = first_name + ' ' + last_name
      pmt.creditCardNumber = cc_number
      pmt.creditCardType = get_card_type
      pmt.type = "CreditCard"
    else
      pmt.achAbaCode = ach_route 
      pmt.achAccountName = first_name + ' ' + last_name
      pmt.achAccountNumber = ach_account
      pmt.achAccountType = ach_acct_type
      pmt.achBankName = ach_bank_name
      pmt.type = "ACH"
    end
    return pmt
  end
  
  def zuora_subscription_id(account)
    get_zuora_object("SELECT Id FROM Subscription WHERE AccountId = '#{account}' and Status = 'Active'").id
  end
  
  ###########################################################################################
  #                               Zuora Subscription Methods                                #
  ###########################################################################################  
  
  def background_subscription()
    zuora_session_prep
    account = update_zuora_account
    package_items.each do |item|
      item.connection = @z
      item.plan_item? ? add_subscription(item, account) : add_service_pack(item, account)
    end
    zuora_session_cleanup
  end
  
  def add_service_pack(item, account="4028e69921ccefc30121f92917ce574a")
    if subscription = get_zuora_object("SELECT Id FROM Subscription WHERE AccountId = '#{account}' and Status = 'Active'")
      amendment_add = add_zuora_amendment("NewProduct", "Add #{item.product}", subscription.id, adjusted_datetime)
      rp = new_zuora_rateplan("NewProduct", item.zuora_product_rate_plan.id, amendment_add.id)
    end
  end
  
  def add_subscription(item, account)
    datetime = ["29","30","31"].include?(day) ? adjusted_datetime - (day.to_i - 1).days + 1.months : adjusted_datetime
    datetime = zuora_datetime(datetime)
    subreq = ZUORA::SubscribeWithExistingAccountRequest.new
    subreq.accountId = account
    subdata = ZUORA::SubscriptionData.new
    subdata.subscription = zuora_subscription(datetime, account)
    data_array = subscription_data_array(item)
    
    subdata.ratePlanData = data_array
    subreq.subscriptionData = subdata
    
    subreq.subscribeOptions = zuora_subscribe_options
    
    sub = @z.subscribeWithExistingAccount([subreq])
    
    post_subscription_amendments(item, account)
  end
  
  def subscription_data_array(item)
    data_array = []
    if item.limited?
      data_array << limited_rate_plan_object(item)
    elsif item.transactional?
      data_array << transactional_rate_plan_object(item)
    elsif item.months_free > 0
      data_array << rate_plan_object(item)
      item.months_free.times do |i|
        data_array << free_month_object(item)
      end
      data_array << standard_events_object(item)
    elsif item.plan == "monthly"
      data_array << rate_plan_object(item)
      if item.discount > 0
        data_array << discount_object(item)
      end
      data_array << standard_events_object(item)
    else
      data_array << annual_rate_plan_object(item)
      if item.discount > 0
        data_array << discount_object(item)
      end
      data_array << standard_events_object(item)
    end
    if registered_nonprofit.unlimited_phone_support?
      data_array << unlimited_phone_support_object
    end
    data_array
  end
  
  def post_subscription_amendments(item, account)
    if item.plan == "annual" && item.discount > 0 && item.months_free == 0
      if item.revert_after > 0
        amendment_to_revert_discount_rate_plan(item, account)
      end
    elsif item.plan == "monthly" && item.discount > 0 && item.months_free == 0
      if item.revert_after > 0
        amendment_to_revert_discount_rate_plan(item, account)
      end
    elsif item.plan == "monthly" && item.months_free > 0 && item.discount > 0
      amendment_to_add_plan_discount(item, account)
      if item.revert_after > 0
        amendment_to_revert_discount_rate_plan(item, account)
      end
    elsif item.plan == "annual" && item.months_free > 0
      datetime = zuora_datetime(month_ahead(item.months_free))
      #remove monthly sub
      rate_plan = get_zuora_object("SELECT Id FROM RatePlan WHERE SubscriptionId = '#{zuora_subscription_id(account)}' and Name = 'Monthly Billing'")
      remove_amendment = add_zuora_amendment("RemoveProduct", "Remove Monthly", zuora_subscription_id(account), datetime)
      rp = new_zuora_rateplan("RemoveProduct", rate_plan.id, remove_amendment.id)
      close_zuora_amendment(remove_amendment, datetime)
      #add annual sub 
      annual_amendment = add_zuora_amendment("NewProduct", "Add Annual", zuora_subscription_id(account), datetime)
      rp = new_zuora_rateplan("NewProduct", item.zuora_product_rate_plan.id, annual_amendment.id)
      close_zuora_amendment(annual_amendment, datetime)
      if item.discount > 0
        #add annual discount for plan after x free months
        amendment_to_add_plan_discount(item, account)
        if item.revert_after > 0
          #remove annual discount after x months
          amendment_to_revert_discount_rate_plan(item, account)
        end
      end
    end
  end
  
  def amendment_to_add_plan_discount(item, account)
    datetime = zuora_datetime(month_ahead(item.months_free))
    discount_amendment = add_zuora_amendment("NewProduct", "Add #{item.plan.titleize} Discount", zuora_subscription_id(account), datetime)
    rp = new_zuora_rateplan("NewProduct", item.zuora_discount_rate_plan.id, discount_amendment.id)
    close_zuora_amendment(discount_amendment, datetime)
  end
  
  def amendment_to_revert_discount_rate_plan(item, account)
    datetime = zuora_datetime(month_ahead(item.months_free + item.revert_after))
    rate_plan = get_zuora_object("SELECT Id FROM RatePlan WHERE SubscriptionId = '#{zuora_subscription_id(account)}' and Name = '#{item.zuora_discount_rate_plan.name}'")
    remove_amendment = add_zuora_amendment("RemoveProduct", "Remove Discount", zuora_subscription_id(account), datetime)
    rp = new_zuora_rateplan("RemoveProduct", rate_plan.id, remove_amendment.id)
    close_zuora_amendment(remove_amendment, datetime)
  end
  
  def free_month_object(item)
    rptrial = ZUORA::RatePlanData.new
    rptrial.ratePlan = new_zuora_rateplan("NewProduct", item.free_month_rate_plan.id, nil, "#{item.plan.titleize} Free Month")
    rptrial.ratePlanCharge = zuora_rate_plan_charge(item.free_month_rate_plan_charge.id)
    rptrial
  end
  
  def unlimited_phone_support_object
    product = get_zuora_object("SELECT Id, Name FROM Product WHERE Name = 'Premium Phone Support'")
    plan = get_zuora_object("SELECT Id FROM ProductRatePlan WHERE ProductId = '#{product.id}'")
    plan_charge = get_zuora_object("SELECT Id FROM ProductRatePlanCharge WHERE ProductRatePlanId = '#{plan.id}'")
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", plan.id, nil, "Premium Phone Support")
    rpdata.ratePlanCharge = zuora_rate_plan_charge(plan_charge.id)
    rpdata
  end
  
  def standard_events_object(item)
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", item.standard_events_rate_plan.id, nil, "#{item.plan.titleize}")
    charges = []
    item.standard_events_rate_plan_charges.each do |charge|
      charges << zuora_transactional_rate_plan_charge(charge.id)
    end
    rpdata.ratePlanCharge = charges
    rpdata
  end
  
  def limited_rate_plan_object(item)
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", item.limited_plan.id, nil, "#{item.plan.titleize} Billing")
    charges = []
    item.limited_plan_charges.each do |charge|
       charges << zuora_transactional_rate_plan_charge(charge.id)
    end
    rpdata.ratePlanCharge = charges
    rpdata
  end
  
  def transactional_rate_plan_object(item)
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", item.transactional_plan.id, nil, "#{item.plan.titleize} Billing")
    charges = []
    item.transactional_plan_charges.each do |charge|
      charges << zuora_transactional_rate_plan_charge(charge.id)
    end
    rpdata.ratePlanCharge = charges
    rpdata
  end
  
  def rate_plan_object(item)
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", item.zuora_monthly_product_rate_plan.id, nil, "#{item.plan.titleize} Billing")
    rpdata.ratePlanCharge = zuora_rate_plan_charge(item.zuora_monthly_product_rate_plan_charge.id)
    rpdata
  end
  
  def annual_rate_plan_object(item)
    rpdata = ZUORA::RatePlanData.new
    rpdata.ratePlan = new_zuora_rateplan("NewProduct", item.zuora_product_rate_plan.id, nil, "#{item.plan.titleize} Billing")
    rpdata.ratePlanCharge = zuora_rate_plan_charge(item.zuora_product_rate_plan_charge.id)
    rpdata
  end
  
  def discount_object(item)
    rpdis = ZUORA::RatePlanData.new
    rpdis.ratePlan = new_zuora_rateplan("NewProduct", item.zuora_discount_rate_plan.id, nil, "#{item.plan.titleize} Discount")
    rpdis.ratePlanCharge = zuora_rate_plan_charge(item.zuora_product_rate_plan_charge.id)
    rpdis
  end
  
  def zuora_subscription(datetime, account)
    sub = ZUORA::Subscription.new
    sub.accountId = account unless account.blank?
    sub.autoRenew = 1
    sub.contractAcceptanceDate = datetime
    sub.contractEffectiveDate = datetime
    sub.serviceActivationDate = datetime
    sub.currency = "USD"
    sub.initialTerm = 50
    sub.renewalTerm = 1
    sub.status = "Active"
    sub.termStartDate = datetime
    sub.name = "#{registered_nonprofit_id.to_s}#{id_suffix} Subscription"
    sub
  end
  
  def zuora_subscribe_options
    subopts = ZUORA::SubscribeOptions.new
    subopts.generateInvoice = "True"
    subopts.processPayments = "False"
    subopts
  end
  
  def zuora_rate_plan_charge(charge_id)
    charge = ZUORA::RatePlanCharge.new
    charge.chargeModel = "FlatFee"
    charge.chargeType = "Recurring"
    charge.productRatePlanChargeId = charge_id
    charge.triggerEvent = "ServiceActivation"
    return charge
  end
  
  def zuora_transactional_rate_plan_charge(charge_id)
    charge = ZUORA::RatePlanCharge.new
    charge.chargeModel = "PerUnit"
    charge.chargeType = "Usage"
    charge.productRatePlanChargeId = charge_id
    charge.triggerEvent = "ServiceActivation"
    return charge
  end
  
  def new_zuora_rateplan(type, rate_plan_id, amendment_id=nil, name=nil)
    rate_plan = ZUORA::RatePlan.new
    rate_plan.name = name unless name.blank?
    rate_plan.amendmentId = amendment_id unless amendment_id.blank?
    rate_plan.amendmentType = type
    case type 
    when "RemoveProduct"
      rate_plan.amendmentSubscriptionRatePlanId = rate_plan_id
    when "NewProduct"
      rate_plan.productRatePlanId = rate_plan_id
    end
    unless amendment_id.blank?
      rp = @z.create([rate_plan])
    else
      return rate_plan
    end
  end
  
  def add_zuora_amendment(type, name, subscription_id, effective_date)
    amendment = ZUORA::Amendment.new
    amendment.type = type
    amendment.status = "Draft"
    amendment.name = name
    amendment.effectiveDate = effective_date
    amendment.subscriptionId = subscription_id
    amend = @z.create([amendment])
    amendment.id = amend.first.id
    return amendment
  end
  
  def close_zuora_amendment(amendment, effective_date)
    amendment.status = "Completed"
    amendment.contractEffectiveDate = effective_date
    amendment.serviceActivationDate = effective_date
    @z.update([amendment])
  end
  
  def pend_zuora_amendment(amendment, effective_date)
    amendment.status = "PendingAcceptance"
    amendment.contractEffectiveDate = effective_date
    amendment.serviceActivationDate = effective_date
    @z.update([amendment])
  end
  
  ###########################################################################################
  #                                    Utility Methods                                      #
  ###########################################################################################
  
  def add_zuora_errors(results)
    msg = results.first.errors.first.message.blank? ? results.first.errors.first.code : results.first.errors.first.message
    cc? ? self.errors.add(:cc_number, msg) : self.errors.add(:ach_bank_name, msg)
  end
  
  def get_unique_name(name, id, limit=40)
    name_length = limit - id.to_s.size - 1
    return "#{name[0..name_length]}-#{id}"
  end
  
  def get_card_type
    if ["34","37"].include?(cc_number[0..1])
      return "AmericanExpress"
    elsif ["51","52","53","54","55"].include?(cc_number[0..1])
      return "MasterCard"
    elsif cc_number.to_s.first == "4"
      return "Visa"
    else
      return "Discover"
    end
  end
 
  def adjusted_datetime(_datetime=self.registered_nonprofit.created_at)
    correct_for_timezone(_datetime)
  end
  
  def day
    adjusted_datetime.strftime("%d")
  end
  
  def month_ahead(x=1)
    ["29","30","31"].include?(day) ? adjusted_datetime - (day.to_i - 1).days + (x+1).months : adjusted_datetime + x.month
  end
  
  def correct_for_timezone(_time=self.registered_nonprofit.created_at, _zip=self.registered_nonprofit.zip)
    #if time_zone_by_zip
    _time = _time.gmtime
    _time -= time_zone_by_zip.to_i.hours  
    #end
    #2009-03-18T13:20:47-07:00
    Time.parse(_time.strftime("%m/%d/%Y %I:%M:%S %p"))
  end
  
  def zuora_datetime(date)
    #2009-03-18T13:20:47-07:00
    date.strftime("%Y-%m-%dT%H:%M:%S-07:00")
  end
  
  def get_suffix
    #this method is an attempt to avoid integrity violations in the zuora sandbox
    if ENV['RAILS_ENV'] == 'production'
      return ""
    else
      return "#{ENV['RAILS_ENV']}#{registered_nonprofit.created_at.strftime("%m%d%Y")}"
    end
  end
end
