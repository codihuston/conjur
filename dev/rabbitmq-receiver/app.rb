# main() {
#   CONT_SESSION_TOKEN=$(cat /tmp/conjur_token| base64 | tr -d '\r\n')
#   VAR_VALUE=$(curl -s -k -H "Content-Type: application/json" -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" https://proxy/secrets/cucumber/variable/BotApp%2FsecretVar)
#   echo "The retrieved value is: $VAR_VALUE"
# }
# main "$@"
# exit

require "base64"
require "bunny"
require "faraday"

def main
  begin
    # cache for secrets
    cache = {}
    # the urlencoded secret name used in the uri
    secret_name = "BotApp/secretVar"
    # connect to rabbitmq
    connection = Bunny.new(
      :host     => ENV["RABBITMQ_HOST"],
      :vhost    => ENV["RABBITMQ_VHOST"],
      :user     => ENV["RABBITMQ_USER"],
      :password => ENV["RABBITMQ_PASS"],
      :automatically_recover => true,
    )

    connection.start

    channel = connection.create_channel
    queue = channel.queue('hello')
    
    begin
      puts('[*] Waiting for messages. To exit press CTRL+C')
      # async/event based
      queue.subscribe(block: false) do |_delivery_info, _properties, body|
        puts("[x] Received #{body}")
        get_secret(body, cache, skip_cache: true)
      end
  
      while true
        get_secret(secret_name, cache)
    
        sleep(1)
      end
    rescue Interrupt => _
      connection.close
    
      exit(0)
    end
    
    connection.close
    #rescue Bunny::TCPConnectionFailedForAllHosts => e
    #rescue Bunny::TCPConnectionFailed => e
    #rescue Bunny::HostListDepleted => e
  rescue Exception => e
    puts e
    puts e.backtrace
    echo "Retrying..."
    sleep(3)
  end
end

def get_secret(name, cache, skip_cache: false)
  # check cache for secret
  if skip_cache == false
    if cache.key?(name) == true
      puts "Cache hit on secret '#{cache[name]}'"
      return cache[name]
    end
  end

  # get conjur token (should be in place before running this app)
  file = File.open("/tmp/conjur_token")
  token = file.readlines.map(&:chomp)
  file.close
  # encode it for fetching secrets later
  encoded_token = Base64.strict_encode64(token[0])

  conn = Faraday.new(
    url: 'http://conjur:3000',
    params: {param: '1'},
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Token token=\"#{encoded_token}\""
    }
  )
  
  response = conn.get("/secrets/cucumber/variable/#{CGI::escape(name)}") 
  puts("Cache update secret '#{name}'': #{response.body}")

  # write to cache
  cache[name] = response.body
end

main
