# slack_emoji_servey
slack絵文字使用率調査スクリプト(ruby)

### Requirement

rubyの実行環境
```
$ ruby -v #動作確認バージョン
ruby 2.6.3p62 (2019-04-16 revision 67580) [x86_64-darwin18]
```

### How to Use
- git cloneする
- slackAppを作成して適切なpermissionをつける
- tokenが取得できたらenvファイルに設定
- スクリプトを実行

### Usage

ダウンロード
```
$ git clone git@github.com:H-Asakawa/slack_emoji_servey.git
```

設定
```
$ cd slack_emoji_servey
$ vim .env #SLACK_API_TOKENとPOST_CHANNEL_NAMEを記入
```

実行
```
$ ruby servey_emoji_ranking_bot.rb 
```

### slackApp permission list
[slackAPImethod公式リファレンス](https://api.slack.com/methods)

- channels:history：チャンネルの履歴データを取得するため
> View messages and other content in the user’s public channels

- channels:read：チャンネル名とチャンネルIDを取得するため
> View basic information about public channels in the workspace

- chat:write：チャンネルに投稿するため
> Send messages on the user’s behalf

- emoji:read：カスタム絵文字を読み取るため
> View custom emoji in the workspace

- reactions:read：反応データを取得するため
> View emoji reactions in the user’s channels and conversations and their associated content

- users:read：ユーザー名とユーザーIDを取得するため
> View people in the workspace

### Settings
dotenvを導入してるので、.envファイルを作成して各々の環境に応じた値を追記してください

SLACK_API_TOKEN = your_token

POST_CHANNEL_NAME = channel_name

### Run
$ ruby servey_emoji_ranking_bot.rb

### Please enter user or channel
```
調べたいのはどっち？入力してね　user or channel
$ user
```

### Please enter user_name
```
絵文字使用率を調べたいユーザー名を入力してください。
$ hiroshi.asakawa
```

### Please enter channel_name
```
絵文字使用率を調べたいチャンネル名を入力してください。
$ _asakawa
```

### Result
![image](https://user-images.githubusercontent.com/36877080/74740149-a9c7ad00-529d-11ea-88fd-def719440fd9.png)

調査対象ユーザー or チャンネルにおける直近1000件の投稿を取得し、
反応データの絵文字をcountして降順に並べ、１~10位をランキング化して通知対象チャンネルに投稿する。



