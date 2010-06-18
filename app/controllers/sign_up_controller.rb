class SignUpController < ApplicationController
   def action

      @productsSelect = Array.new
      @item = SelectItem.new
      @item.name = "-- SELECT ONE --"
      @item.value = ""
      @item.selected = ""
      @productsSelect << @item

      @ratePlansSelect = Array.new
      @item = SelectItem.new
      @item.name = "-- SELECT A PRODUCT ABOVE --"
      @item.value = ""
      @item.selected = ""
      @ratePlansSelect << @item

      @chargesSelect = Array.new
      @item = SelectItem.new
      @item.name = "-- SELECT A RATE PLAN ABOVE --"
      @item.value = ""
      @item.selected = ""
      @chargesSelect << @item

      @Name = nil;
      @FirstName = nil;
      @LastName = nil;
      @WorkEmail = nil;
      @WorkPhone = nil;
      @Address1 = nil;
      @Address2 = nil;
      @City = nil;
      @State = nil;
      @Country = nil;
      @PostalCode = nil;
      @CreditCardType = nil;
      @CreditCardNumber = nil;
      @CreditCardHolderName = nil;
      @CreditCardExpirationMonth = nil;
      @CreditCardExpirationYear = nil;
      @CreditCardPostalCode = nil;

      render :file => 'app\views\sign_up\signup.rhtml'
   end
   def list
   end
   def show
   end
   def new
   end
   def create
   end
   def edit
   end
   def update
   end
   def delete
   end
end

class SelectItem
   attr_accessor :name, :value, :selected
end
