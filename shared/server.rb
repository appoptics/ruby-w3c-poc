require 'sinatra/base'
require 'rack/handler/puma'

require 'net/http'

class Server < Sinatra::Base
  ports = { 'A' => 4000, 'O' => 4100, 'L' => 4200 }
  File.write("req.log", "")

  get '/*' do
    id = settings.id
    port = request.port
    headers = request.env.slice('HTTP_PLAYER', 'HTTP_X_TRACE', 'HTTP_TRACEPARENT', 'HTTP_TRACESTATE')

    chain = request.path_info[1..].gsub(/[^AOL]/, '')
    player = chain[0] || ""

    if chain.empty?
      status 400
      'No Chain.'
    elsif player != id
      status 400
      "Chain for port #{port} must start with #{id}."
    else 
      rest = chain[1..]
      nxt = rest[0]

      got = "#{Time.now.to_i} #{player} #{port} GOT - #{headers}\n"
      File.write("req.log", got, mode: 'a')

      unless nxt.nil? || nxt.empty?
        shift = ports[nxt] - ports[id]

        downstream = port + shift + 1
        uri = URI("http://localhost:#{downstream}/#{rest}")

        request = Net::HTTP::Get.new(uri)
        request['player'] = player

        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            response = http.request request 
          end
        rescue Errno::ECONNREFUSED => e
        end

      end
      status 200
      "#{chain} Chain."
    end
  end
end
