#--
#   Copyright (c) 2010 Zuora, Inc.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy of 
#  this software and associated documentation files (the "Software"), to use copy, 
#  modify, merge, publish the Software and to distribute, and sublicense copies of 
#  the Software, provided no fee is charged for the Software.  In addition the
#  rights specified above are conditioned upon the following:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
#  or promote products derived from this Software without specific prior written
#  permission from Zuora, Inc.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
#  ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++
class SignUpController < ApplicationController
  
  CHARGE_SELECT_LIST = "Id, Name, AccountingCode, DefaultQuantity, Type, Model, ProductRatePlanId"
  @productId = nil
  @prpId = nil
  @charges = nil
  @status = ""
  
  def action
    
    @productId = params[:Products]
    @prpId = params[:RatePlans]
    @charges = params[:Charges]
    
    @Name = params[:Name]
    @FirstName = params[:FirstName]
    @LastName = params[:LastName]
    @WorkEmail = params[:WorkEmail]
    @WorkPhone = params[:WorkPhone]
    @Address1 = params[:Address1]
    @Address2 = params[:Address2]
    @City = params[:City]
    @State = params[:State]
    @Country = params[:Country]
    @PostalCode = params[:PostalCode]
    @CreditCardType = params[:CreditCardType]
    @CreditCardNumber = params[:CreditCardNumber]
    @CreditCardHolderName = params[:CreditCardHolderName]
    @CreditCardExpirationMonth = params[:CreditCardExpirationMonth]
    @CreditCardExpirationYear = params[:CreditCardExpirationYear]
    @CreditCardPostalCode = params[:CreditCardPostalCode]
    
    @zuora = ZuoraInterface.new
    @zuora.session_start
    
    init
    
    if (validate)
      subscribe
    end
    
    @zuora.session_cleanup
    
    render :file => 'app\views\sign_up\signup.rhtml'
    
    
  end
  
  def init
    
    @productsSelect = Array.new
    @item = SelectItem.new
    @item.name = "-- SELECT ONE --"
    @item.value = ""
    @item.selected = ""
    @productsSelect << @item
    
    r = @zuora.query("select Id, Name FROM Product")
    for rec in r.result.records do
      @item = SelectItem.new
      @item.name = rec.name
      @item.value = rec.id
      if rec.id == @productId
        @item.selected = "SELECTED"
      end
      @productsSelect << @item
    end
    
    @ratePlansSelect = Array.new
    @item = SelectItem.new
    @item.name = "-- SELECT A PRODUCT ABOVE --"
    @item.value = ""
    @item.selected = ""
    @ratePlansSelect << @item
    
    if !@productId.nil?
      r = @zuora.query("select Id, Name FROM ProductRatePlan where ProductId = '" + @productId + "'")
      if r.result.size > 0 
        for rec in r.result.records do
          @item = SelectItem.new
          @item.name = rec.name
          @item.value = rec.id
          if rec.id == @prpId || r.result.size == 1
            @item.selected = "SELECTED"
          end
          @ratePlansSelect << @item
        end
      end
    end
    
    @chargesSelect = Array.new
    
    if !@prpId.nil?
      r = @zuora.query("select " + CHARGE_SELECT_LIST + " from ProductRatePlanCharge where ProductRatePlanId = '" + @prpId + "'")
      if (r.result.size > 0)
        for rec in r.result.records do
          @item = SelectItem.new
          @item.name = rec.name
          @item.value = rec.id
          @item.selected = "SELECTED"
          @chargesSelect << @item
        end
      else
        @item = SelectItem.new
        @item.name = "-- SELECT A RATE PLAN ABOVE --"
        @item.value = ""
        @item.selected = ""
        @chargesSelect << @item
      end
    end
    
  end
  
  def validate
    
    @valid = true
    @isSubmit = !params[:commit].nil?
    if !@isSubmit
      return false
    else 
      
      if @productId.nil?
        status = "Please select a Product."
        return false
      end
      if @prpId.nil?
        status = "Please select a Rate Plan."
        return false
      end
      if @charges.nil? || @charges.length == 0
        status = "Please select Charges."
        return false
      end
      
      @valid = @valid && validateValue(:Name)
      @valid = @valid && validateValue(:FirstName)
      @valid = @valid && validateValue(:LastName)
      @valid = @valid && validateValue(:WorkEmail)
      @valid = @valid && validateValue(:WorkPhone)
      @valid = @valid && validateValue(:Address1)
      @valid = @valid && validateValue(:City)
      @valid = @valid && validateValue(:State)
      @valid = @valid && validateValue(:Country)
      @valid = @valid && validateValue(:PostalCode)
      @valid = @valid && validateValue(:CreditCardHolderName)
      @valid = @valid && validateValue(:CreditCardNumber)
      @valid = @valid && validateValue(:CreditCardExpirationMonth)
      @valid = @valid && validateValue(:CreditCardExpirationYear)
      @valid = @valid && validateValue(:CreditCardType)
    end
    
  end
  
  def validateValue(param)
    @value = params[param]
    if @value.nil? || @value == ""
      @status = param.to_s + " is a required value.<br>"
      return false
    end
    return true
  end
  
  def subscribe
    
    @month = @CreditCardExpirationMonth.to_i
    @year = @CreditCardExpirationYear.to_i
    
    @chargesArray = Array.new
    for id in @charges do
      @charge = ZUORA::ProductRatePlanCharge.new
      @charge.id = id
      @charge.productRatePlanId = @prpId
      @chargesArray << @charge
    end
    
    @subscriptionName = @Name + " New Signup (" + Time.now.to_s + ")"
    
    @status = "subscribe: " + @subscriptionName
    
    @acc = ZUORA::Account.new
    @acc.name = @Name
    @acc.status = "Draft"
    @acc.paymentTerm = "Due Upon Receipt"
    @acc.batch = "Batch1"
    @acc.billCycleDay = 1
    @acc.allowInvoiceEdit = true
    @acc.autoPay = false
    @acc.currency = "USD"
    
    @con = ZUORA::Contact.new
    @con.firstName = @FirstName
    @con.lastName = @LastName
    @con.workEmail = @WorkEmail
    @con.workPhone = @WorkPhone
    @con.address1 = @Address1
    @con.address2 = @Address2
    @con.city = @City
    @con.state = @State
    @con.country = @Country
    @con.postalCode = @PostalCode
    
    @pm = ZUORA::PaymentMethod.new
    @pm.type = "CreditCard"
    @pm.creditCardHolderName= @CreditCardHolderName
    @pm.creditCardCity= @City
    @pm.creditCardState= @State
    @pm.creditCardPostalCode= @CountryPostalCode
    @pm.creditCardType= @CreditCardType
    @pm.creditCardNumber= @CreditCardNumber
    @pm.creditCardExpirationMonth= @CreditCardExpirationMonth
    @pm.creditCardExpirationYear= @CreditCardExpirationYear
    
    @calendar = nil
    @sub = ZUORA::Subscription.new
    @sub.name = @subscriptionName
    @sub.notes = nil
    @sub.termStartDate = @calendar
    @sub.contractEffectiveDate= @calendar
    @sub.contractAcceptanceDate= @calendar
    @sub.serviceActivationDate= @calendar
    @sub.initialTerm = 12
    @sub.renewalTerm = 12
    
    @sd = ZUORA::SubscriptionData.new
    @sd.subscription = @sub
    
    @subscriptionRatePlanDataArray = makeRatePlanData(@chargesArray)
    @sd.ratePlanData = @subscriptionRatePlanDataArray
    
    @options = ZUORA::SubscribeOptions.new
    @options.generateInvoice = false 
    @options.processPayments = false
    
    @subRequest = ZUORA::SubscribeRequest.new
    @subRequest.account = @acc
    @subRequest.billToContact = @con
    @subRequest.paymentMethod = @pm
    @subRequest.subscriptionData = @sd
    @subRequest.subscribeOptions = @options
    
    @subscribes = ZUORA::Subscribe.new
    @subscribes << @subRequest
    @result = @zuora.subscribe(@subscribes)[0]
    
    @status = createMessage(@result)
    
  end
  
  def makeRatePlanData(chargesArray) 
    
    @data = Array.new
    
    for charge in chargesArray do 
      @ratePlanData = ZUORA::RatePlanData.new
      
      @ratePlan = ZUORA::RatePlan.new
      @ratePlanData.ratePlan = @ratePlan
      @ratePlan.amendmentType = "NewProduct"
      @ratePlan.productRatePlanId = charge.productRatePlanId
      
      @ratePlanCharge = ZUORA::RatePlanCharge.new
      @ratePlanChargeArray = Array.new
      @ratePlanChargeArray << @ratePlanCharge
      @ratePlanData.ratePlanCharge = @ratePlanChargeArray
      
      @ratePlanCharge.productRatePlanChargeId = charge.id
      if !charge.defaultQuantity.nil? && charge.defaultQuantity > 0 
        @ratePlanCharge.quantity = 1
      end
      @ratePlanCharge.triggerEvent = "ServiceActivation"
      
      @data << @ratePlanData;
    end
    
    return @data;
  end
  
  def createMessage(result) 
    @resultString = ""
    if !@result.nil?
      if result.success
        @resultString = @resultString + "<b>Subscribe Result: Success</b>"
        @resultString = @resultString + "<br>&nbsp;&nbsp;Account Id: " + result.accountId
        @resultString = @resultString + "<br>&nbsp;&nbsp;Account Number: " + result.accountNumber
        @resultString = @resultString + "<br>&nbsp;&nbsp;Subscription Id: " + result.subscriptionId
        @resultString = @resultString + "<br>&nbsp;&nbsp;Subscription Number: " + result.subscriptionNumber
        @resultString = @resultString + "<br>&nbsp;&nbsp;Invoice Number: " + (result.paymentTransactionNumber.nil? ? "" : result.paymentTransactionNumber) 
        @resultString = @resultString + "<br>&nbsp;&nbsp;Payment Transaction: " + (result.paymentTransactionNumber.nil? ? "" : result.paymentTransactionNumber)
        
      else 
        @resultString = @resultString + "<b>Subscribe Result: Failed</b>"
        if !@result.errors.nil?
          for error in @result.errors do
            @resultString = @resultString + "<br>&nbsp;&nbsp;Error Code: " + error.code
            @resultString = @resultString + "<br>&nbsp;&nbsp;Error Message: " + error.message
          end
        end
      end
      return @resultString
    end
    
  end
end

class SelectItem
  attr_accessor :name, :value, :selected
end
