abort "Must provide port number as argument." if ARGV[0].nil? || !ARGV[0].match(/^(\d)+$/)

require "rack"
require '../shared/server.rb'

require 'appoptics_apm'

Server.set :id, 'L'
Rack::Server.start(:server=> 'Puma', :app => Server.new , :Port => ARGV[0])
