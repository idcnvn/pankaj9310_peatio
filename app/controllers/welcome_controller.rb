class WelcomeController < ApplicationController
  layout 'landing'

  def index
	require "net/https"
	require "uri"
	url = URI("https://api.coinmarketcap.com/v2/ticker/?convert=USD&limit=10")
	http = Net::HTTP.new(url.host, url.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = Net::HTTP::Get.new(url)
	response = http.request(request)
	data  =  JSON.parse(response.read_body)['data']
	@currency =  {'BTC':0.0, 'ETH':0.0, 'XRP':0.0, 'BCH':0.0, 'LTC':0.0, 'XLM':0.0};
	data.each do |i,idx|
		@currency.each do |x,y|
			if(x.to_s == idx['symbol'].to_s)
				@currency[x] = idx['quotes']['USD']['price'] 	
			end
		end
	end
	puts @currency
  end
end
