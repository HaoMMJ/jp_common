# -*- coding: utf-8 -*-
class MinnaController < ApplicationController
  require "addressable/uri"

  # {"id"=>"32",
  # "lesson_id"=>"1",
  # "hiragana"=>"～からきました。",
  # "kanji"=>"～から来ました",
  # "roumaji"=>"～karakimashita",
  # "mean"=>"(tôi) đến từ ~",
  # "mean_unsigned"=>"(toi) den tu ~",
  # "tag"=>"",
  # "favorite"=>"",
  # "kanji_id"=>"来&128※来&68",
  # "cn_mean"=>"lai"}
  def create_minna_raw_data
    1.upto(50) do |i|
      url = Addressable::URI.parse("http://mina.mazii.net/api/getKotoba.php?lessonid=#{i}").normalize.to_str
      puts "send request #{i}"
      res = RestClient.get(url)
      if res.code == 200
        json = ActiveSupport::JSON.decode(res)
        json.each do |w|
          jlpt = JlptWord.where("word = ?", w["kanji"]).first
          default_level = (i <= 20) ? 5 : 4
          level = jlpt.present? ? jlpt.level : default_level
          vocab = Vocabulary.new
          vocab.kanji       = w["kanji"]
          vocab.kana        = w["hiragana"]
          vocab.cn_mean     = w["cn_mean"].split.map(&:capitalize).join(' ') if w["cn_mean"].present?
          vocab.mean        = w["mean"]
          vocab.level       = level
          vocab.from_source = "Mazii"
          vocab.save!
        end
      end
      sleep 5 
    end
  end

  def create_minna_dictionary
    Vocabulary.all.each do |v|
      DicVocab.create!(dictionary_id: 1, vocabulary_id: v.id)
    end
  end

  def create_minna_quizlet
    dic = Dictionary.where("name = ?", "Minna no nihongo").first
    File.open("quizlet/minna", 'w') do |f|
      dic.vocabularies.each do |v|
        line = ""
        if v.kanji.present?
          line = "#{v.kanji}"
          line += " (#{v.kana})" if v.kana.present?
          line += "\t"
          line += "#{v.cn_mean}: " if v.cn_mean != v.mean && v.cn_mean.present?
          line += "#{v.mean}"
        else
          line = "#{v.kana}\t#{v.mean}"
        end  
        f.puts line 
      end
    end
  end
end