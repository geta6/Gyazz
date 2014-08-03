# Gyazzの再実装

Node, Express, MongoDBで再実装しました。
ちゃんと動いてない機能も沢山ありますが…

[![Build Status](https://travis-ci.org/masuilab/Gyazz.svg?branch=master)](https://travis-ci.org/masuilab/Gyazz)


# 必要環境

- Node.js 0.10.x
- MongoDB 2.x
- memcached


# Install Dependencies


    % brew install mongodb memcached

    % npm i


## 起動

    % GYAZZ_URL=http://gyazz.com
    % PORT=3000 npm start

## Debug

    % PORT=3000 DEBUG=gyazz* npm start


## 開発

gruntでファイル更新をwatchし、継続的にtestを実行しつつcoffeeをjsにコンパイルしたりできます。

    % grunt


## Testのみ実行

コミットする前に必ずtestは走らせましょう。

    % npm test


## Deploy on Heroku

### create app

    % heroku create
    % git push heroku master

### config

    % heroku config:add TZ=Asia/Tokyo
    % heroku config:set "DEBUG=gyazz*"
    % heroku config:set NODE_ENV=production
    % heroku config:set GYAZZ_URL=http://(app_name).herokuapp.com

### enable MongoDB plug-in

    % heroku addons:add mongolab
    # or
    % heroku addons:add mongohq

### enable memcached plug-in

    % heroku addons:add memcachier

### logs

    % heroku logs --num 300
    % heroku logs --tail
