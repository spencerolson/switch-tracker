require 'net/http'
require 'json'
require 'twilio-ruby'

BEST_BUY_API_KEY = ENV['BEST_BUY_KEY']
grey_joycon_sku = "5670003"
red_blue_joycon_sku = "5670100"
grey_url = "https://api.bestbuy.com/v1/stores(area(41.936645,-87.706683,25))+products(sku=#{grey_joycon_sku})?format=json&show=storeId,storeType,address,city,region,name,phone,products.name,products.sku,products&pageSize=10&apiKey=#{BEST_BUY_API_KEY}"
stores_with_grey = JSON.parse(Net::HTTP.get(URI(grey_url)))["stores"]

red_blue_url = "https://api.bestbuy.com/v1/stores(area(41.936645,-87.706683,25))+products(sku=#{red_blue_joycon_sku})?format=json&show=storeId,storeType,address,city,region,name,phone,products.name,products.sku,products&pageSize=10&apiKey=#{BEST_BUY_API_KEY}"
stores_with_red_blue = JSON.parse(Net::HTTP.get(URI(red_blue_url)))["stores"]

text_message = ""
if stores_with_grey.any?
  stores_with_grey.each do |store|
    address = "#{store["address"]}, #{store["city"]}, #{store["region"]}"
    text_message += "Grey Switch at #{address} #{store["phone"]}\n"
  end
elsif stores_with_red_blue.any?
  stores_with_red_blue.each do |store|
     address = "#{store["address"]}, #{store["city"]}, #{store["region"]}"
     text_message += "Red/Blue Switch at #{address} #{store["phone"]}\n"
  end
end

# Texting
have_not_yet_texted = File.size("/Users/solson/switch-tracker/switch-log.txt") == 0
if have_not_yet_texted && (stores_with_grey.any? || stores_with_red_blue.any?)
  puts "SENT TEXT AT at #{Time.now}. STORES WITH GREY? #{stores_with_grey.any?} STORES WITH RED/BLUE? #{stores_with_red_blue.any?}"
  client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
  twilio_number = ENV['TWILIO_NUMBER']
  telephone_numbers = [ENV['MY_NUMBER'], ENV['A_FRIENDS_NUMBER']]

  telephone_numbers.each do |recipient|
    client.messages.create(
      from: twilio_number,
      to: recipient,
      body: text_message[0..1000]
    )
  end
end
