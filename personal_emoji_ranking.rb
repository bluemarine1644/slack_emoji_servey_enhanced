require 'net/http'
require 'uri'
require "json"
require 'pp'

# slackAPI用に取得したtoken
token = "your_token"

# 通知対象チャンネル名
post_channel_name = "post_channel_name"

# SlackAPI：users.list
res     = Net::HTTP.get(URI.parse("https://slack.com/api/users.list?token=#{token}&pretty=1"))
hash    = JSON.parse(res)
members = hash["members"]

# ユーザー名を知ってればすぐ調べられるようにuserIDとuser名のハッシュを作っておく
member_lists = {}

members.each do |member|
  member_lists[member["name"].to_sym] = member["id"]
end

p '絵文字使用率を調べたいユーザー名を入力してください。'
personal_name = gets.chomp!

if member_lists[personal_name.to_sym].nil?
  puts "該当ユーザーが存在しません"
  return
end

# 該当ユーザーのIDを取得する
user_id = member_lists[personal_name.to_sym]
count      = 1000 #slackAPIの取得可能数の限界値。timestampをずらして1000件ずつ取得すれば全件取得できるらしい

# SlackAPI：reaction.list
res = Net::HTTP.get(URI.parse("https://slack.com/api/reactions.list?token=#{token}&count=#{count}&user=#{user_id}&pretty=1"))

hash  = JSON.parse(res)
items = hash["items"]

messages = []
items.each do |item|
  messages << item["message"]
end

reactions = []
messages.each do |message|
  reactions << message["reactions"]
end
reactions.flatten!

# あとでcount数を加算するために初期値0でハッシュを作っておく
results = Hash.new(0)

reactions.each do |reaction|
  name                 = reaction["name"]
  results[name.to_sym] += reaction["count"]
end

# 結果表示
puts "#{personal_name}の絵文字使用率ランキング1〜10位"
result_data = []
results.sort_by { |_, v| -v }.to_a.first(10).each do |result|
  result_data << result
  puts "#{result[0].to_s.rjust(30, " ")}:#{result[1]}回"
end

# 該当チャンネルに投稿をするAPIを叩く
target_uri        = "https://slack.com/api/chat.postMessage"

uri = URI.parse(target_uri)
req = Net::HTTP::Post.new(uri)

# 後でjoinして配列内の文字列を全て結合する
contents = ["#{personal_name}の絵文字使用率ランキング1〜10位\n"]
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
