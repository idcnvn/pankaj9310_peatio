module Worker
  class SmsNotification

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!
      # raise "TWILIO_NUMBER not set" if ENV['TWILIO_NUMBER'].blank?
      message = payload[:message]
      to = Phonelib.parse(payload[:phone]).international
      textlocal_client(message, to)      
      # twilio_client.api.account.messages.create(
      #   from: ENV["TWILIO_NUMBER"],
      #   to:   Phonelib.parse(payload[:phone]).international,
      #   body: payload[:message]
      # )
    end

    def twilio_client
      Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])#, ssl_verify_peer: false
    end

    def textlocal_client(message, number)
      require "rubygems"
      require "net/https"
      require "uri"
      require "json"
      requested_url = 'http://api.textlocal.in/send?username=pankaj@sgit.io&hash=a91f9a5df70a99eb6a29af118a44326cfc8425753f45974e1c9b127ce600331a &test=0&sender=TXTLCL&numbers='+number+'&message='+URI.escape(message)
      uri = URI.parse(requested_url)
      http = Net::HTTP.start(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(request)
      response = JSON.parse(res.body)
      puts (response)
      end
  end
end
