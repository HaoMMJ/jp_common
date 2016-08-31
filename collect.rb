require 'mysql'
require 'pry'

con = Mysql.new('172.17.0.1', 'root', '', 'common_jp')  
con.query("SET NAMES UTF8")
words = con.query("select kanji from words")

puts "SUCCESS"
con.close 