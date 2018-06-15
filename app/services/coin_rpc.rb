require 'net/http'
require 'uri'
require 'json'

class CoinRPC

  class JSONRPCError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  def initialize(uri)
    @uri = URI.parse(uri)
    @rest_uri = URI.parse(uri)
    # puts @rest_uri
    # puts @uri
  end

  def self.[](currency)
    c = Currency.find_by_code(currency.to_s)
    if c && c.rpc
      name = c.family || 'BTC' || 'LTC' || 'XRP' || 'XLM'
      "::CoinRPC::#{name}".constantize.new(c.rpc)
    end
  end

  def method_missing(name, *args)
    handle name, *args
  end

  def handle
    raise "Not implemented"
  end
  class BTC < self
    def handle(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      begin
        # raise JSONRPCError, resp['error'] if resp['error']
        result = resp['result']
        result.symbolize_keys! if result.is_a? Hash
        result
      rescue
        'N/A'
      end

    end
    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      raise ConnectionRefusedError
    end

    def safe_getbalance
      begin
        getbalance
      rescue
        'N/A'
      end
    end
  end

  class XRP < self
    def handle(name, *args)
      post_body = {"jsonrpc" => "1.0", 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      # raise JSONRPCError, resp['error'] if resp['error']
      raise_if_unsuccessful!(resp)
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end
    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      raise ConnectionRefusedError
    end

    def safe_getbalance
      begin
        getBalances
      rescue
        'N/A'
      end
    end
  end
  # class XRP < self
  #   R_B58_DICT = 'rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz'

  #   def currency
  #     Currency.find_by_code('xrp')
  #   end

  #   def handle(name, *args)
  #     post_body = { method: name, params: args }.to_json
  #     resp = JSON.parse(http_post_request(post_body))
  #     raise_if_unsuccessful!(resp)
  #     result = resp['result']
  #     result.symbolize_keys! if result.is_a? Hash
  #     result
  #   end

  #   def http_post_request(post_body)
  #     http    = Net::HTTP.new(@uri.host, @uri.port)
  #     request = Net::HTTP::Post.new(@uri.request_uri)
  #     request.basic_auth @uri.user, @uri.password
  #     request.content_type = 'application/json'
  #     request.body = post_body
  #     http.request(request).body
  #   rescue Errno::ECONNREFUSED
  #     raise ConnectionRefusedError
  #   end

  #   def getnewaddress(args = nil)
  #     resp = JSON.parse(RestClient.get("#{@rest_uri}/v1/wallet/new").body)
  #     raise_if_unsuccessful!(resp)
  #     resp['wallet']
  #   end

  #   def listtransactions(account, number = 100)
  #     txs = PaymentAddress.where(currency: 'xrp').map do |pa|
  #       post_body = {
  #         method: 'account_tx',
  #         params: [{
  #           account: pa.address,
  #           ledger_index_max: -1,
  #           ledger_index_min: -1,
  #           limit: number
  #         }]
  #       }.to_json

  #       resp = JSON.parse(http_post_request(post_body))
  #       raise_if_unsuccessful!(resp)

  #       resp['result']['transactions'].map do |t|
  #         {
  #           'txid'     => t['tx']['hash'],
  #           'address'  => t['tx']['Destination'],
  #           'amount'   => t['tx']['Amount'],
  #           'category' => 'receive',
  #           'walletconflicts' => []
  #         }
  #       end
  #     end

  #     txs.flatten
  #   end

  #   def gettransaction(txid)
  #     post_body = {
  #       method: 'tx',
  #       params: [
  #         transaction: txid,
  #         binary: false
  #       ]
  #     }.to_json

  #     resp = JSON.parse(http_post_request(post_body))
  #     raise_if_unsuccessful!(resp)

  #     {
  #       amount: resp['result']['Amount'].to_d / 1_000_000,
  #       confirmations: resp['result']['meta']['AffectedNodes'].size,
  #       timereceived: resp['result']['date'] + 946684800,
  #       txid: txid,
  #       details: [{
  #          account:  'payment',
  #          address:  resp['result']['Destination'],
  #          amount:   resp['result']['Amount'].to_d / 1_000_000,
  #          category: 'receive'
  #       }]
  #     }
  #   end

  #   def validateaddress(address = nil)
  #     post_body = {
  #       method: 'ledger_entry',
  #       params: [
  #         {
  #           account_root: address,
  #           ledger_index: 'validated',
  #           type: 'account_root'
  #         }
  #       ]
  #     }.to_json

  #     resp = JSON.parse(http_post_request(post_body))
  #     raise_if_unsuccessful!(resp)

  #     {
  #       isvalid: resp['result']['status'] == 'success',
  #       ismine: false,
  #       address: address
  #     }
  #   end

  #   def settxfee(fee)
  #     @tx_fee = fee * 1_000_000
  #   end

  #   def sendtoaddress(address, amount, fee)
  #     fs = FundSource.find_by(uid: address)
  #     issuer = fs.member.payment_addresses.find_by(currency: fs.currency_value)

  #     resp = JSON.parse(
  #       RestClient.get(
  #         "#{@rest_uri}/v1/accounts/#{issuer.address}/payments/paths/#{address}/#{amount}+XRP"
  #       ).body
  #     )

  #     uuid = JSON.parse(
  #       RestClient.get("#{@rest_uri}/v1/uuid").body
  #     )['uuid']

  #     resp = JSON.parse(
  #       RestClient.post(
  #         "#{@rest_uri}/v1/accounts/#{issuer.address}/payments",
  #         {
  #           secret: issuer.secret,
  #           payment: resp['payments'].last,
  #           client_resource_id: uuid
  #         }.to_json,
  #         content_type: :json,
  #         accept: :json
  #       ).body
  #     )

  #     Rails.logger.info("\n#{resp}")
  #     Rails.logger.info 'OK'

  #     Rails.logger.info(RestClient.get(resp['status_url']).body)
  #   end

  #   def getbalance(account = nil)
  #     post_body = {
  #       method: 'account_info',
  #       params: [
  #         account: account || Currency.find_by_code('xrp').assets['accounts'].sample['address'],
  #         strict: true,
  #         ledger_index: 'validated'
  #       ]
  #     }.to_json

  #     resp = JSON.parse(http_post_request(post_body))
  #     raise_if_unsuccessful!(resp)
  #     resp['result']['account_data']['Balance'].to_f / 1_000_000
  #   end

  #   def safe_getbalance
  #     getbalance || 'N/A'
  #   end
  #   private

  #     def raise_if_unsuccessful!(response)
  #       (response['error'] || response.dig('result', 'error')).tap do |error|
  #         raise JSONRPCError, error if error
  #       end
  #   end
  # end
  
  class ETH < self
    def handle(name, *args)
      post_body = {"jsonrpc" => "2.0", 'method' => name, 'params' => args, 'id' => '1' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end
    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      raise ConnectionRefusedError
    end

    def safe_getbalance
      begin
        (open(@uri + '/cgi-bin/total.cgi').read.rstrip.to_f)
      rescue
        'N/A'
      end
    end
  end
  class XLM < self
    def handle(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end
    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      raise ConnectionRefusedError
    end

    def safe_getbalance
      begin
        getbalance
      rescue
        'N/A'
      end
    end
  end
end
