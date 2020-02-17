## bot.rb
require 'http'
require 'json'
require 'dotenv'
Dotenv.load

# ''の間にAPIトークンを入力する
bot_token = ENV['SLACK_BOT_API_TOKEN']
target_channel_name = ENV['TARGET_CHANNNEL_NAME']

# POSTリクエストの結果を response に代入
response = HTTP.post("https://slack.com/api/chat.postMessage",
                     params: {
                       token:   bot_token,
                       channel: target_channel_name, # Botを招待したチャンネル
                       text: "はじめまして", # 投稿するメッセージ
                       as_user: true
                     })

# response の内容を表示
puts JSON.pretty_generate(JSON.parse(response.body))
