abort "Must provide port number as argument." if ARGV[0].nil? || !ARGV[0].match(/^(\d)+$/)

# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

require "rack"
require '../shared/server.rb'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'w3c-poc'
  c.use_all() # enables all instrumentation!
end

Server.set :id, 'O'
Rack::Server.start(:server=> 'Puma', :app => Server.new , :Port => ARGV[0])
