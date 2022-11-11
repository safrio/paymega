ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'])

require_relative 'paymega_service'

service = PaymegaService.new(username: 'username', password: 'password')

pay_res = service.pay(attributes: { service: 'payment_card_usd_hpp', amount: '20 bucks', currency: 'wrong', customer: {} })
puts "Pay result: #{pay_res.inspect}"

puts '* ' * 3

payout_res = service.payout(attributes: { service: 'payment_card_usd_hpp', amount: 100, currency: 'USD', customer: {} })
puts "Payout result: #{payout_res.inspect}"

puts '* ' * 3

callback_res = PaymegaService.parse_callback('{ "data": { "status": "status_sample" }}')
puts "Parse callback result: #{callback_res.inspect}"
