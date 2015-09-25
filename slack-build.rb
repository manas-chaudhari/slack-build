require 'sinatra'
require 'json'

post '/' do
#  push = JSON.parse(request.body.read)
  puts "I got some JSON: #{request.body.read}"

  content_type :text
  "This doesn't do anything yet. Coming soon :)"
end
