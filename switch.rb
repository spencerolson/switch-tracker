require 'net/http'
require 'json'
require 'twilio-ruby'

class TwilioApi
  def initialize
    @twilio_account_sid = ENV['TWILIO_ACCOUNT_SID']
    @twilio_number = ENV['TWILIO_NUMBER']
    @twilio_auth_token = ENV['TWILIO_AUTH_TOKEN']
  end

  def send_text(recipient, message)
    puts "sending message #{message.inspect} to #{recipient}"
    client.messages.create(
      from: @twilio_number,
      to: recipient,
      body: message[0..1500]
    )
  end

  def client
    @client ||= Twilio::REST::Client.new(@twilio_account_sid, @twilio_auth_token)
  end
end

class BestBuyApi
  def initialize
    @best_buy_api_key = ENV['BEST_BUY_KEY']
  end

  def stores_with_product(product, lat, long)
    sku = product[:sku]
    product_name = product[:name]
    url = URI("https://api.bestbuy.com/v1/stores(area(#{lat},#{long},25))+products(sku=#{sku})?format=json&show=storeId,storeType,address,city,region,name,phone,products.name,products.sku,products&pageSize=10&apiKey=#{@best_buy_api_key}")
    stores_with_product = JSON.parse(Net::HTTP.get(url))["stores"]
    stores_with_product.map { |store| format_store(store, product_name) }.join("\n")
  end

  def format_store(store, product_name)
    address = "#{store["address"]}, #{store["city"]}, #{store["region"]}"
    "#{product_name} available at #{address} #{store['phone']}"
  end
end

class SwitchTracker
  def initialize
    @twilio_api = TwilioApi.new
    @best_buy_api = BestBuyApi.new
    @recipients = [ENV['MY_NUMBER'], ENV['A_FRIENDS_NUMBER']]
  end

  def run
    if already_found_switch?
      puts "Already found a switch! Nothing to do."
      return
    end

    lat = 42.067250
    long = -87.789963
    products = [
      { sku: 6364253, name: "Nintendo Switch (Gray Joy-Con)" },
      { sku: 6364255, name: "Nintendo Switch (Red/Neon Blue Joy-Con)" },
    ]

    messages = products.map { |product| @best_buy_api.stores_with_product(product, lat, long) }
    combined_messages = messages.reject { |message| message.empty? }.join("\n")

    if combined_messages.empty?
      puts "Ran at #{Time.now}. No switches available."
    else
      system "touch found_switch.txt"
      message_recipients(combined_messages)
    end
  end

  def already_found_switch?
    system "test -f found_switch.txt"
  end

  def message_recipients(text_message)
    @recipients.each do |recipient|
      @twilio_api.send_text(recipient, text_message)
    end
  end
end

tracker = SwitchTracker.new
tracker.run
