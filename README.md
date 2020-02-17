# slack_emoji_servey
絵文字使用率調査スクリプト

### スクリプト実行コマンド
$ ruby servey_emoji_ranking_bot.rb

### user or channnelを入力
$ user

### user名を入力
$ hiroshi.asakawa

#### 存在しない場合はプログラム終了

#### 存在する場合
調査対象ユーザー or チャンネルにおける直近1000件の反応データを取得し、
絵文字使用率ランキング１~10位を算出して通知対象チャンネルに投稿する。

### 下記はdotenvを導入してるので、.envファイルを作成して追記してください
SLACK_API_TOKEN = your_token
POST_CHANNNEL_NAME = channel_name

### slackApp側で許可が必要になるpermission一覧
#### channels:history
View messages and other content in the user’s public channels

#### channels:read
View basic information about public channels in the workspace

#### chat:write
Send messages on the user’s behalf

#### emoji:read
View custom emoji in the workspace

#### reactions:read
View emoji reactions in the user’s channels and conversations and their associated content

#### users:read
View people in the workspace
