# slack_emoji_servey
slackの対象ユーザー・チャンネル・すべてのチャンネルの絵文字使用回数ランキング1〜10位を表示するスクリプト(ruby)

### 機能
- ユーザー単位での絵文字使用回数ランキング表示
- チャンネル単位での絵文字使用回数ランキング表示
- すべてのチャンネルでの絵文字使用回数ランキング表示
- 数字で選択できるメニュー
- プログレスバー表示
- APIレート制限対策
- 結果のファイル保存機能

### slackApp permission list
[slackAPImethod公式リファレンス](https://api.slack.com/methods)

- users:read：ユーザー情報の取得
  > View people in the workspace

- reactions:read：リアクション情報の取得
  > View emoji reactions in the user's channels and conversations and their associated content

- conversations:history：チャンネルのメッセージ履歴を取得
  > View messages and other content in public channels that servey_emoji_ranking_bot has been added to

- conversations:read：チャンネル一覧の取得
  > View basic information about public channels in the workspace

- chat:write：（使用する場合）チャンネルへの投稿
  > Send messages on the user's behalf

注意: 現在のバージョンでは、chat:writeは実際には使用されていません（コメントアウトされています）。Slackに投稿する機能を有効にする場合に必要になります。

### プライベートチャンネル対応について
プライベートチャンネルにアクセスするには、以下の追加スコープが必要です：
- groups:read：プライベートチャンネルへのアクセス
- mpim:read：マルチ人DMへのアクセス
- im:read：DMへのアクセス

### Requirement

rubyの実行環境を用意
```
$ ruby -v #動作確認したバージョン
ruby 2.6.3p62 (2019-04-16 revision 67580) [x86_64-darwin18]
```

### How to Use
- git cloneする
- slackAppを作成して適切なpermissionをつける
- tokenが取得できたらenvファイルに設定
- スクリプトを実行

### Tutorial

#### Install
```
$ git clone https://github.com/bluemarine1644/slack_emoji_servey_enhanced.git
```

#### Settings
```
$ cd slack_emoji_servey_enhanced
$ vim .env #SLACK_API_TOKENとPOST_CHANNEL_NAMEを記入
```

dotenvを導入してるので、.envファイルを作成して環境変数を設定してください
```
SLACK_API_TOKEN = your_token
POST_CHANNEL_NAME = channel_name
```

#### Run
```
$ ruby servey_emoji_ranking_bot.rb 
```

### メニュー選択
```
調べたいのはどれ？番号を入力してください：
1: ユーザーの絵文字使用回数
2: チャンネルの絵文字使用回数
3: すべてのチャンネルの絵文字使用回数
$ 1
```

### ユーザーを調査する場合
```
絵文字使用回数を調べたいユーザー名を入力してください。
$ hiroshi.asakawa
```

### チャンネルを調査する場合
```
絵文字使用回数を調べたいチャンネル名を入力してください。(#は省略可)
$ general
```

### すべてのチャンネルを調査する場合
```
$ 3
取得可能なすべてのチャンネルから絵文字リアクションを収集しています...
```

### Result
![image](https://user-images.githubusercontent.com/36877080/74740149-a9c7ad00-529d-11ea-88fd-def719440fd9.png)

調査対象ユーザー・チャンネル・すべてのチャンネルにおける直近1000件の投稿を取得し、
反応データの絵文字をcountして降順に並べ、１~10位をランキング化して表示します。
結果はファイルに保存することもできます。

### ファイル保存機能
集計結果を保存するか聞かれたら、`y`を入力することでファイルに保存できます。
```
この結果をファイルに保存しますか？ (y/n): y
ファイルに保存しました: emoji_ranking_すべてのチャンネル_20250521-145626.txt
```

保存されたファイルには、すべての絵文字ランキングと統計情報が含まれています。