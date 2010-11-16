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
require 'zuora/api'

class ZuoraInterface
  
  def make_account(accountName)
    acc = ZUORA::Account.new
    acc.allowInvoiceEdit = 0
    acc.name = accountName
    acc.currency = "USD"
    acc.autoPay = 0
    acc.status = "Draft"
    acc.paymentTerm = "Due Upon Receipt"
    acc.batch = "Batch1"
    acc.billCycleDay = "01"
    return acc
  end
  
  def make_contact(accountId)
    con = ZUORA::Contact.new
    con.accountId = accountId
    con.address1 = '4901 Morena Blvd';
    con.city = 'San Diego';
    con.country = 'United States';
    con.firstName = 'Robert';
    con.lastName = 'Smith';
    con.postalCode = '92117';
    con.state = 'Virginia';
    con.workEmail = 'robert@smith.com';
    return con
  end
  
  def make_payment_method(accountId)
    pmt = ZUORA::PaymentMethod.new
    pmt.accountId = accountId
    pmt.creditCardAddress1 = '52 Vexford Lane';
    pmt.creditCardCity = 'Anaheim';
    pmt.creditCardCountry = 'United States';
    pmt.creditCardExpirationMonth = '12';
    pmt.creditCardExpirationYear = '2010';
    pmt.creditCardHolderName = 'Firstly Lastly';
    pmt.creditCardNumber = '4111111111111111';
    pmt.creditCardPostalCode = '22042';
    pmt.creditCardState = 'California';
    pmt.creditCardType = 'Visa';
    pmt.type = 'CreditCard';
    return pmt
  end
  
  def create_active_account(name)
    
    val = false
    session_start 
    account = make_account(name)
    result = create([account])
    puts result.first.inspect
    
    if result.first.success
      
      accountId = result.first.id
      payment = make_payment_method(accountId)
      result = create([payment])
      
      if result.first.success
        
        paymentId = result.first.id
        con = make_contact(accountId)
        result = create([con])
        
        if result.first.success
          conId = result.first.id
          
          account.id = accountId
          account.status = 'Active'
          account.billToId = conId
          account.soldToId = conId
          result = update([account])
          
          if result.first.success
            val = account
          else
            add_errors(result)
          end
          
        else
          add_errors(result)
        end
      else
        add_errors(result)
      end
    else
      add_errors(result)
    end
    return val
  end
  
  def query(query)
    q = ZUORA::Query.new
    q.queryString = query
    results = @z.query(q)
    return results
  end
  
  def create(objs)
    return @z.create(objs)
  end
  
  def update(objs)
    return @z.update(objs)
  end
  
  def delete(type, ids)
    d = ZUORA::Delete.new
    d.type = type
    d.ids = ids
    return @z.delete(d)
  end
  
  def subscribe(sub)
    return @z.subscribe(sub)
  end
  
  def get_object(query)
    object = lookup(query)
    unless object.result.size == 0
      return object.result.records.first  
    else
      return nil
    end
  end
  
  def get_object_array(query)
    object = lookup(query)
    unless object.result.size == 0
      return object.result.records
    else
      return []
    end
  end
  
  def get_driver
    @z ||= Zuora::Billing::Api.instance.driver
  end
  
  def driver
    get_driver
  end
  
  def login
    loginargs = ZUORA::Login.new
    loginargs.username = ZUORA_USER
    loginargs.password = ZUORA_PASSWORD
    @session = ZUORA::SessionHeader.new
    @session.session = @z.login(loginargs).result.session
  end
  
  def session_start
    get_driver
    session_cleanup
    login
    @z.headerhandler.set @session
    @z.wiredump_dev = STDERR
  end
  
  def session_cleanup
    @z.headerhandler.delete(@session) if @session
  end
end

public 

def run_tests
  
  t = ZuoraInterface.new
  t.session_start
  
  # create active account
  e = t.create_active_account("name" + String(Time.now.to_f))
  puts "Created Account: " + e.id
  
  # query it
  r = t.query("SELECT Id, Name FROM Account WHERE Name = '#{e.name}' and status = 'Active'")
  e = r.result.records[0]
  puts "Queried Account: " + e.to_s
  
  # delete it
  r = t.delete("Account", [e.id])
  puts "Deleted Account? " + r[0].success.to_s
  
  t.session_cleanup

end

if __FILE__ == $0
end
