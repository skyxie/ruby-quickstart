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
module ZUORA

endpoint_url = ARGV.shift
obj = Soap.new(endpoint_url)

# run ruby with -d to see SOAP wiredumps.
obj.wiredump_dev = STDERR if $DEBUG

# SYNOPSIS
#   login(parameters)
#
# ARGS
#   parameters      Login - {http://api.zuora.com/}login
#
# RETURNS
#   parameters      LoginResponse - {http://api.zuora.com/}loginResponse
#
# RAISES
#   fault           LoginFault - {http://fault.api.zuora.com/}LoginFault
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.login(parameters)

# SYNOPSIS
#   subscribe(parameters)
#
# ARGS
#   parameters      Subscribe - {http://api.zuora.com/}subscribe
#
# RETURNS
#   parameters      SubscribeResponse - {http://api.zuora.com/}subscribeResponse
#
# RAISES
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.subscribe(parameters)

# SYNOPSIS
#   subscribeWithExistingAccount(parameters)
#
# ARGS
#   parameters      SubscribeWithExistingAccount - {http://api.zuora.com/}subscribeWithExistingAccount
#
# RETURNS
#   parameters      SubscribeResponse - {http://api.zuora.com/}subscribeResponse
#
# RAISES
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.subscribeWithExistingAccount(parameters)

# SYNOPSIS
#   create(parameters)
#
# ARGS
#   parameters      Create - {http://api.zuora.com/}create
#
# RETURNS
#   parameters      CreateResponse - {http://api.zuora.com/}createResponse
#
# RAISES
#   fault           InvalidTypeFault - {http://fault.api.zuora.com/}InvalidTypeFault
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.create(parameters)

# SYNOPSIS
#   update(parameters)
#
# ARGS
#   parameters      Update - {http://api.zuora.com/}update
#
# RETURNS
#   parameters      UpdateResponse - {http://api.zuora.com/}updateResponse
#
# RAISES
#   fault           InvalidTypeFault - {http://fault.api.zuora.com/}InvalidTypeFault
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.update(parameters)

# SYNOPSIS
#   delete(parameters)
#
# ARGS
#   parameters      Delete - {http://api.zuora.com/}delete
#
# RETURNS
#   parameters      DeleteResponse - {http://api.zuora.com/}deleteResponse
#
# RAISES
#   fault           InvalidTypeFault - {http://fault.api.zuora.com/}InvalidTypeFault
#   fault           InvalidValueFault - {http://fault.api.zuora.com/}InvalidValueFault
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.delete(parameters)

# SYNOPSIS
#   query(parameters)
#
# ARGS
#   parameters      Query - {http://api.zuora.com/}query
#
# RETURNS
#   parameters      QueryResponse - {http://api.zuora.com/}queryResponse
#
# RAISES
#   fault           MalformedQueryFault - {http://fault.api.zuora.com/}MalformedQueryFault
#   fault           InvalidQueryLocatorFault - {http://fault.api.zuora.com/}InvalidQueryLocatorFault
#   fault           UnexpectedErrorFault - {http://fault.api.zuora.com/}UnexpectedErrorFault
#
parameters = nil
puts obj.query(parameters)




end
