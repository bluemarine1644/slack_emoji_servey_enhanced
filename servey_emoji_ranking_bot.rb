require 'net/http'
require 'uri'
require "json"
require 'pp'
require 'dotenv'
Dotenv.load

# .envに定義して利用してください
SLACK_API_TOKEN   = ENV['SLACK_API_TOKEN'] # slackAPI用に取得したtoken
POST_CHANNEL_NAME = ENV['POST_CHANNEL_NAME'] # 通知対象チャンネル名
COUNT             = 1000 #slackAPIの取得可能数の限界値。timestampをずらして1000件ずつ取得すれば全件取得できるらしい
$target_name      = nil

def get_reactions_from_user
  p '絵文字使用回数を調べたいユーザー名を入力してください。'
  $target_name = gets.chomp!

# SlackAPI：users.list
  puts "Slack APIからユーザー情報を取得中..."
  
  uri = URI.parse("https://slack.com/api/users.list?pretty=1")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  res = http.request(req)
  hash = JSON.parse(res.body)
  
  # API呼び出しのレスポンスチェック
  unless hash["ok"]
    puts "APIエラー: #{hash["error"]}"
    # テストデータを使わず、空の配列を返す
    return []
  end
  
  members = hash["members"]
  if members.nil?
    puts "メンバーリストが取得できませんでした"
    return []
  end

# ユーザー名を知ってればすぐ調べられるようにuserIDとuser名のハッシュを作っておく
  member_lists = {}

  members.each do |member|
    # ユーザー名とディスプレイネームの両方を登録
    member_lists[member["name"].to_sym] = member["id"] if member["name"]
    if member["profile"] && member["profile"]["display_name"]
      member_lists[member["profile"]["display_name"].to_sym] = member["id"]
    end
    if member["profile"] && member["profile"]["real_name"]
      member_lists[member["profile"]["real_name"].to_sym] = member["id"]
    end
  end

  # デバッグ用: 使用可能なユーザー名のリストを表示
  puts "検索可能なユーザー名一覧:"
  member_lists.keys.sort.first(10).each do |name|
    puts "- #{name}"
  end
  
  if member_lists[$target_name.to_sym].nil?
    puts "#{$target_name}は存在しません"
    return []
  end

# 該当ユーザーのIDを取得する
  user_id = member_lists[$target_name.to_sym]
  puts "ユーザーID: #{user_id}のリアクション情報を取得中..."

# SlackAPI：reaction.list
  uri = URI.parse("https://slack.com/api/reactions.list?count=#{COUNT}&user=#{user_id}&pretty=1")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  res = http.request(req)
  hash = JSON.parse(res.body)
  
  # API呼び出しのレスポンスチェック
  unless hash["ok"]
    puts "APIエラー: #{hash["error"]}"
    return []
  end
  
  items = hash["items"]
  if items.nil?
    puts "リアクションアイテムが取得できませんでした"
    return []
  end

  messages = []
  items.each do |item|
    messages << item["message"] if item["message"]
  end

  reactions = []
  messages.each do |message|
    reactions << message["reactions"] if message["reactions"]
  end
  
  flattened_reactions = reactions.flatten
  puts "#{flattened_reactions.size}個のリアクションが見つかりました"
  flattened_reactions
end

def get_reactions_from_channel
  p '絵文字使用回数を調べたいチャンネル名を入力してください。(#は省略可)'
  $target_name = gets.chomp!

# チャンネルリスト取得
  puts "Slack APIからチャンネル情報を取得中..."
  
  uri = URI.parse("https://slack.com/api/conversations.list?types=public_channel")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  res = http.request(req)
  hash = JSON.parse(res.body)
  
  # API呼び出しのレスポンスチェック
  unless hash["ok"]
    puts "APIエラー: #{hash["error"]}"
    # テストデータを使わず、空の配列を返す
    return []
  end
  
  channels = hash["channels"]
  if channels.nil?
    puts "チャンネルリストが取得できませんでした"
    return []
  end

# チャンネル名だけ知ってればすぐ調べられるように、チャンネルIDとチャンネル名のハッシュを作っておく
  channel_lists = {}
  messages      = []

  channels.each do |channel|
    channel_lists[channel["name"].to_sym] = channel["id"] if channel["name"]
  end
  
  # デバッグ用: 使用可能なチャンネル名のリストを表示
  puts "検索可能なチャンネル名一覧 (最初の10件):"
  channel_lists.keys.sort.first(10).each do |name|
    puts "- #{name}"
  end

  # 入力されたチャンネル名から「#」を削除（ユーザーが#付きで入力した場合に対応）
  clean_target_name = $target_name.gsub(/^#/, '')

  if channel_lists[clean_target_name.to_sym].nil?
    puts "#{$target_name}は存在しません"
    return []
  end

# 該当チャンネルのIDを取得する
  channel_id = channel_lists[clean_target_name.to_sym]
  puts "チャンネルID: #{channel_id}のメッセージ履歴を取得中..."

# SlackAPI：channels.history
  uri = URI.parse("https://slack.com/api/conversations.history?inclusive=true&count=#{COUNT}&channel=#{channel_id}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  res = http.request(req)
  hash = JSON.parse(res.body)
  
  # API呼び出しのレスポンスチェック
  unless hash["ok"]
    puts "APIエラー: #{hash["error"]}"
    return []
  end
  
  messages = hash["messages"]
  if messages.nil?
    puts "メッセージが取得できませんでした"
    return []
  end
  
  reactions = []
  messages.each do |message|
    reactions << message["reactions"] if message["reactions"]
  end

# 整形
  flattened_reactions = reactions.compact.flatten
  puts "#{flattened_reactions.size}個のリアクションが見つかりました"
  flattened_reactions
end

def get_reactions_from_all_channels
  puts "取得可能なすべてのチャンネルから絵文字リアクションを収集しています..."
  $target_name = "すべてのチャンネル"

  # チャンネルリスト取得
  puts "Slack APIからチャンネル情報を取得中..."
  
  uri = URI.parse("https://slack.com/api/conversations.list?types=public_channel&limit=1000")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  res = http.request(req)
  hash = JSON.parse(res.body)
  
  # API呼び出しのレスポンスチェック
  unless hash["ok"]
    puts "APIエラー: #{hash["error"]}"
    return []
  end
  
  channels = hash["channels"]
  if channels.nil? || channels.empty?
    puts "チャンネルリストが取得できませんでした"
    return []
  end

  puts "#{channels.size}個のチャンネルが見つかりました。すべてのチャンネルから絵文字リアクションを収集します..."
  
  all_reactions = []
  processed_channels = 0
  total_channels = channels.size
  
  # プログレスバー表示用の変数
  progress_width = 50
  
  # 各チャンネルから反応を取得
  channels.each do |channel|
    channel_name = channel["name"]
    channel_id = channel["id"]
    
    processed_channels += 1
    
    # プログレスバーの表示
    percent_done = (processed_channels.to_f / total_channels * 100).to_i
    progress_chars = (processed_channels.to_f / total_channels * progress_width).to_i
    print "\r["
    progress_chars.times { print "=" }
    (progress_width - progress_chars).times { print " " }
    print "] #{percent_done}% (#{processed_channels}/#{total_channels}) 処理中: #{channel_name}"
    
    # SlackAPI：channels.history
    uri = URI.parse("https://slack.com/api/conversations.history?inclusive=true&count=#{COUNT}&channel=#{channel_id}")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{SLACK_API_TOKEN}"
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    res = http.request(req)
    history_hash = JSON.parse(res.body)
    
    # API呼び出しのレスポンスチェック - このチャンネルでエラーがあってもスキップして次へ
    unless history_hash["ok"]
      puts "\n  チャンネル #{channel_name} のメッセージ取得でエラー: #{history_hash["error"]} - スキップします"
      next
    end
    
    messages = history_hash["messages"]
    if messages.nil? || messages.empty?
      next
    end
    
    channel_reactions = []
    messages.each do |message|
      channel_reactions << message["reactions"] if message["reactions"]
    end
    
    flattened_channel_reactions = channel_reactions.compact.flatten
    
    # リアクションが見つかった場合のみ表示
    if flattened_channel_reactions.size > 0
      puts "\n  #{channel_name}: #{flattened_channel_reactions.size}個のリアクションが見つかりました"
    end
    
    all_reactions.concat(flattened_channel_reactions)
    
    # APIレート制限に引っかからないよう、少し待機（Tier 3 メソッドの場合、1分間に50リクエストが上限）
    sleep(0.2) if processed_channels % 5 == 0
  end

  puts "\nすべてのチャンネルからの集計が完了しました"
  puts "合計 #{all_reactions.size}個のリアクションが見つかりました"
  all_reactions
end

def post_emoji_ranking(reactions, target_type)
  #取得したreactionsをランキング化して表示
  # あとでcount数を加算するために初期値0でハッシュを作っておく
  results = Hash.new(0)

  # reactionsが空の場合は処理を中断
  if reactions.nil? || reactions.empty?
    puts "リアクションデータが空です。ランキングを作成できません。"
    return
  end

  #ユーザーを対象にした場合はcountは使用せず単に1プラスする。チャンネルを対象にした場合はcountを加算する。
  if target_type == "user"
    reactions.each do |reaction|
      next unless reaction && reaction["name"]
      name = reaction["name"]
      results[name.to_sym] += 1
    end
  else
    reactions.each do |reaction|
      next unless reaction && reaction["name"] && reaction["count"]
      name = reaction["name"]
      results[name.to_sym] += reaction["count"]
    end
  end
  
  # 結果が空の場合は処理を中断
  if results.empty?
    puts "集計結果が空です。ランキングを作成できません。"
    return
  end

  # コンソール結果表示用
  puts "#{$target_name}の絵文字使用回数ランキング1〜10位"
  result_data = []
  results.sort_by { |_, v| -v }.first(10).each do |result|
    result_data << result
    puts "#{result[0].to_s.rjust(30, " ")}:#{result[1]}回"
  end

  # 詳細な結果をコンソールに表示する（Slackへの投稿の代わり）
  puts "\n===== テスト出力（Slackへの投稿の代わり） ====="
  puts "#{$target_name}の絵文字使用回数ランキング1〜10位"
  
  result_data.each.with_index(1) do |data, n|
    puts "#{n}位　:#{data[0]}:は#{data[1]}回です"
  end
  
  puts "========================================="
  
  # ファイルへの保存を提案
  print "この結果をファイルに保存しますか？ (y/n): "
  save_answer = gets.chomp.downcase
  
  if save_answer == "y"
    timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
    filename = "emoji_ranking_#{$target_name.gsub(/[^0-9A-Za-z_]/, '_')}_#{timestamp}.txt"
    
    File.open(filename, 'w') do |file|
      file.puts "#{$target_name}の絵文字使用回数ランキング (#{Time.now.strftime('%Y年%m月%d日 %H:%M:%S')})"
      file.puts "-" * 50
      
      # ランキングの詳細
      results.sort_by { |_, v| -v }.each.with_index(1) do |data, n|
        file.puts "#{n}位　:#{data[0]}: #{data[1]}回"
      end
      
      # サマリー情報
      file.puts "-" * 50
      file.puts "総リアクション数: #{results.values.sum}"
      file.puts "ユニーク絵文字数: #{results.keys.size}"
    end
    
    puts "ファイルに保存しました: #{filename}"
  end
  
  # Slackへの投稿処理はテストのためコメントアウト
  # post_api_url = "https://slack.com/api/chat.postMessage"
  # uri = URI.parse(post_api_url)
  # req = Net::HTTP::Post.new(uri)
  #
  # contents = ["#{$target_name}の絵文字使用回数ランキング1〜10位\n"]
  # result_data.each.with_index(1) do |data, n|
  #   contents << "#{n}位　:#{data[0]}:は#{data[1]}回です\n"
  # end
  #
  # post_data = { token:   "#{SLACK_API_TOKEN}",
  #               channel: "#{POST_CHANNEL_NAME}",
  #               text:    contents.join, }
  #
  # req.set_form_data(post_data)
  #
  # req_options = {
  #   use_ssl: uri.scheme == "https"
  # }
  #
  # Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  #   http.request(req)
  # end
end

puts "調べたいのはどれ？番号を入力してください："
puts "1: ユーザーの絵文字使用回数"
puts "2: チャンネルの絵文字使用回数"
puts "3: すべてのチャンネルの絵文字使用回数"
target_num = gets.chomp!

# reactionsを取得
case target_num
when "1"
  target = "user"
  reactions = get_reactions_from_user
when "2"
  target = "channel"
  reactions = get_reactions_from_channel
when "3"
  target = "all_channels"
  reactions = get_reactions_from_all_channels
else
  puts "1, 2, 3 のいずれかの番号を入力してください"
  exit
end

post_emoji_ranking(reactions, target)
