# -*- coding: utf-8 -*-
require 'mongo'
 
#データベースと接続
connection = Mongo::Connection.new
#connection = Mongo::Connection.new('localhost');
#connection = Mongo::Connection.new('localhost'27017);
 
puts 'データベース一覧'
puts connection.database_names

puts ''
puts 'データベースinfo [名前,byte数]'
connection.database_info.each{ |info| puts info.inspect }

#データベース選択(存在しなければ作成)
db = connection.db('gyazz')
 
#コレクション選択
coll = db.collection('Pages')

puts coll

#coll.find_one('title' => 'shokai').each { |row|
#  puts row['title']
#}

puts coll.find('title' => 'shokai').to_a.length




