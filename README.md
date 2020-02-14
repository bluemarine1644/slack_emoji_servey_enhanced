# slack_emoji_servey
絵文字使用率調査スクリプト

### スクリプト実行コマンド
$ ruby servey_emoji_ranking_bot.rb

### user or channnelを入力
$ user

### user名を入力
$ hiroshi.asakawa

#### 存在しない場合
終了

#### 存在する場合
調査対象ユーザー or チャンネルにおける直近1000件の反応データを取得し、
絵文字使用率ランキング１~10位を算出して通知対象チャンネルに投稿する。

### 下記は自分の環境に応じて任意の値に変更すること
slackAPIトークン：$token
通知対象チャンネル：$post_channel_name

### 備考
記号の使用率には人間の無意識が反映されているかもしれない。
