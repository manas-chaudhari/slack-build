require 'sinatra'
require "sinatra/reloader" if development?

get '/' do
#  push = JSON.parse(request.body.read)
  puts "Received request: #{params}"

  content_type :text

  channel = params[:channel_id]
  return "Error: Did not receive channel id" if channel.nil?

  build_params = params[:text]
  build_params = "" if build_params.nil?

  build_cmd = "./build.sh #{channel} #{build_params}"
  result = `#{build_cmd}`
  status = $?.exitstatus

  response_title = status == 0 ? "Will get back to you with the build" : "Something went wrong"
  content_type :text
  return "#{response_title}:\n#{result}"
end
