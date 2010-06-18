class SignUpController < ApplicationController
  
  CHARGE_SELECT_LIST = "Id, Name, AccountingCode, DefaultQuantity, Type, Model, ProductRatePlanId"
  @productId = nil
  @prpId = nil
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
    
    @zuora = ZuoraApi.new
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
    
    @valid = true;
    @isSubmit = !params[:commit].nil?
    if !@isSubmit
      return false;
    else 
      
      if @productId.nil?
        status = "Please select a Product.";
        return false;
      end
      if @prpId.nil?
        status = "Please select a Rate Plan.";
        return false;
      end
      if @charges.nil?
        status = "Please select Charges.";
        return false;
      end
      
      @valid = @valid && validateValue(:Name);
      @valid = @valid && validateValue(:FirstName);
      @valid = @valid && validateValue(:LastName);
      @valid = @valid && validateValue(:WorkEmail);
      @valid = @valid && validateValue(:WorkPhone);
      @valid = @valid && validateValue(:Address1);
      @valid = @valid && validateValue(:City);
      @valid = @valid && validateValue(:State);
      @valid = @valid && validateValue(:Country);
      @valid = @valid && validateValue(:PostalCode);
      @valid = @valid && validateValue(:CreditCardHolderName);
      @valid = @valid && validateValue(:CreditCardNumber);
      @valid = @valid && validateValue(:CreditCardExpirationMonth);
      @valid = @valid && validateValue(:CreditCardExpirationYear);
      @valid = @valid && validateValue(:CreditCardType);
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
    
  end
  
end

class SelectItem
  attr_accessor :name, :value, :selected
end
