require 'net/http'
require 'uri'
require "json"
require 'pp'

# slackAPI用に取得したtoken
token = "your_token"

# 通知対象チャンネル名
post_channel_name = "post_channel_name"

# チャンネルリスト取得
res      = Net::HTTP.get(URI.parse("https://slack.com/api/channels.list?token=#{token}"))
hash     = JSON.parse(res)
channels = hash["channels"]

# チャンネル名だけ知ってればすぐ調べられるように、チャンネルIDとチャンネル名のハッシュを作っておく
channel_lists = {}
messages      = []

channels.each do |channel|
  channel_lists[channel["name"].to_sym] = channel["id"]
  messages << channel["messages"]
end

# チャンネルhistoryのmessagesのreactionsからnameとcountを取得してランキング化する
p '絵文字使用率を調べたいチャンネル名を入力してください。'
channel_name = gets.chomp!

if channel_lists[channel_name.to_sym].nil?
  puts "チャンネル名が存在しません"
  return
end

channel_id = channel_lists[channel_name.to_sym]
count      = 1000
res        = Net::HTTP.get(URI.parse("https://slack.com/api/channels.history?inclusive=true&count=#{count}&channel=#{channel_id}&token=#{token}"))

hash      = JSON.parse(res)
messages  = hash["messages"]
reactions = []

messages.each do |message|
  reactions << message["reactions"]
end

# 整形
reactions.compact!.flatten!

# あとでcount数を加算するために初期値0でハッシュを作っておく
results = Hash.new(0)

reactions.each do |reaction|
  name                 = reaction["name"]
  results[name.to_sym] += reaction["count"]
end

# 結果表示
puts "#{channel_name}チャンネルの絵文字使用率ランキング1〜10位"
result_data = []
results.sort_by { |_, v| -v }.to_a.first(10).each do |result|
  result_data << result
  puts "#{result[0].to_s.rjust(30, " ")}:#{result[1]}回"
end

# 該当チャンネルに投稿をするAPIを叩く
target_uri = "https://slack.com/api/chat.postMessage"

uri = URI.parse(target_uri)
req = Net::HTTP::Post.new(uri)

# 後でjoinして配列内の文字列を全て結合する
contents = ["#{channel_name}チャンネルの絵文字使用率ランキング1〜10位\n"]
result_data.each.with_index(1) do |data, n|
  contents << "#{n}位　:#{data[0]}:は#{data[1]}回です\n"
end

post_data = { token:   "#{token}",
              channel: "#{post_channel_name}",
              text:    contents.join, }

req.set_form_data(post_data)

req_options = {
  use_ssl: uri.scheme == "https"
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(req)
end
