module Private
  class MarketsController < BaseController
    skip_before_action :auth_member!, only: [:show]
    before_action :visible_market?
    after_action :set_default_market

    layout false

    def show
      @bid = params[:bid]
      @ask = params[:ask]

      @market        = current_market
      @markets       = Market.all.sort
      @market_groups = @markets.map(&:quote_unit).uniq

      @bids   = @market.bids
      @asks   = @market.asks
      @trades = @market.trades
      country
      # default to limit order
      @order_bid = OrderBid.new ord_type: 'limit'
      @order_ask = OrderAsk.new ord_type: 'limit'
      coin_rate
      set_member_data if current_user
      gon.jbuilder
      # binding.pry
    end
    def coin_rate
      require "net/https"
      require "uri"
      ask_coin = params['ask'].upcase
      bid_coin = params['bid'].upcase
      @coin_sell = 0.0
      @coin_buy = 0.0
      url = URI("https://api.coinmarketcap.com/v2/ticker/?convert="+bid_coin+"&limit=10")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      response = http.request(request)
      data  =  JSON.parse(response.read_body)['data']
      data.each do |i,idx|
        if(ask_coin == idx['symbol'].to_s)
          rate = (idx['quotes'][bid_coin]['price']).to_f
          puts rate
          @coin_sell = rate + rate*0.03
          @coin_buy = rate - rate*0.03   
        end
      end
    end
    private

    def visible_market?
      redirect_to market_path(Market.first) if not current_market.visible?
    end

    def set_default_market
      cookies[:market_id] = @market.id
    end

    def set_member_data
      @member = current_user
      @orders_wait = @member.orders.with_currency(@market).with_state(:wait)
      @trades_done = Trade.for_member(@market.id, current_user, limit: 100, order: 'id desc')
    end

  end
end
