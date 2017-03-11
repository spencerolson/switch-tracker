require 'nokogiri'
require 'open-uri'
require 'twilio-ruby'

doc = Nokogiri::HTML(open("https://www.zoolert.com/bestbuy-inventory-checker/?r=2%7CUS%7CBB%7C60618%7C25%7C5670003"))
nodes = doc.xpath('//b[contains(text(), "Available Qty")]')
result = nodes.map do |node|
  {
    qty: node.next_sibling.text.strip.to_i,
    tel: node.previous.previous.previous.previous.text,
    loc: node.previous.previous.previous.previous.previous.previous.previous.previous.text,
    price: "$#{node.next_sibling.next_sibling.next_sibling.text.strip}"
  }
end

in_stock = result.select { |option| option[:qty] > 0 }

text_message = ""
if in_stock.any?
  text_message += "-- Spencer's Switch Finder --\n"
  in_stock.each do |available|
    if available[:qty] == 1
      text_message += "1 Switch is available at:\n"
    else
      text_message += "#{available[:qty]} Switches are available at:\n"
    end
    text_message += "  #{available[:loc]}\n"
    text_message += "  telephone number: #{available[:tel]}\n"
    text_message += "  price: #{available[:price]}\n\n"
  end

else
  text_message += "None available. Don't A Gimme A Dat"
end

# Texting
have_not_yet_texted = File.size("/Users/spencer/programming/switch-runner/switch-log.txt") == 0
if have_not_yet_texted && in_stock.any?
  puts "SENT TEXT AT at #{Time.now}"
  client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
  twilio_number = ENV['TWILIO_NUMBER']
  telephone_numbers = [ENV['MY_NUMBER'], ENV['A_FRIENDS_NUMBER']]

  telephone_numbers.each do |recipient|
    client.messages.create(
      from: twilio_number,
      to: recipient,
      body: text_message[0..600]
    )
  end
end
