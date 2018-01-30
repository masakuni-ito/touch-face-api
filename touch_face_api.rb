require 'open-uri'
require 'nokogiri'
require 'json'

employees = {}

html = Nokogiri::HTML(open('https://liginc.co.jp/member'))
html.css('article.author_member_item').each do |ele|
  next if ele.nil?

  name = ele.css('.author_member_item--name').first
  img = ele.css('.author_member_item--photo1').first

  next if name.nil? || img.nil?

  employees[name.inner_text.to_s] = img.attr('data-original').to_s
end

employees.each do |name, url|
  uri = URI('https://eastasia.api.cognitive.microsoft.com/face/v1.0/detect')
  uri.query = URI.encode_www_form({
      # Request parameters
      'returnFaceId' => 'true',
      'returnFaceLandmarks' => 'false',
      'returnFaceAttributes' => 'emotion'
  })

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request['Ocp-Apim-Subscription-Key'] = ENV['SUB_KEY']
  request.body = "{\"url\":\"#{url}\"}"
  
  response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
  end

  result = ''
  body = JSON.parse(response.body)
  if body.instance_of?(Array) && body.count > 0 && body.first.has_key?('faceAttributes')
    result = name + ":" + body.first['faceAttributes']['emotion']['happiness'].to_s
  else
    result = name + ":人間ではない"
  end

  puts result
  STDOUT.flush

  sleep 5
end

