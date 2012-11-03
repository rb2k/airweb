require 'rubygems'
require 'bundler/setup'
require 'airvideo-ng'
require 'sinatra'
require "base64"

configure do
  server_host = 'something.dyndns.org'
  server_port = 45631
  server_password = 'YOUR_PASSWORD'
  raise "You have to enter your server data in the script" if server_host == 'something.dyndns.org'
  $airvideo = AirVideo::Client.new(server_host,server_port,server_password)
  $airvideo.max_width = 640
  $airvideo.max_height = 480
end

get '/' do
  $airvideo.cd('/')
  items = $airvideo.ls
  @folders = items.select{|item| item.is_a? AirVideo::Client::FolderObject}
  @videos = items.select{|item| item.is_a? AirVideo::Client::VideoObject}
  erb :index
end

get '/folder/:folder_location' do
  path = Base64.decode64(params[:folder_location])
  $airvideo.cd(path)
  items = $airvideo.ls
  @folders = items.select{|item| item.is_a? AirVideo::Client::FolderObject}
  @videos = items.select{|item| item.is_a? AirVideo::Client::VideoObject}
  erb :index
end


get '/play/:video_location/:playback_mode/:bitrate' do
  playback_mode = params[:playback_mode]
  bitrate = params[:bitrate]
  video_location  = Base64.decode64(params[:video_location])
  video_dir = video_location.split('/')[0..-2].join('/') + "/"
  video_name  = video_location.split('/').last
  $airvideo.cd(video_dir)
  video_file = $airvideo.ls.select{|item| item.name == video_name}.first
  case playback_mode
  when 'native'
    @video_live_url  = video_file.url
  when 'convert'
    already_retried = false
    begin
      @video_live_url  = video_file.live_url + "?q=#{bitrate}"
    rescue
      unless already_retried
        already_retried = true
        retry
      end
      return "Airvideo can't convert this file, sorry"
    end
  else
    raise 'unknown playback mode: #{playback_mode.inspect}'
  end
  
  erb :play

end
