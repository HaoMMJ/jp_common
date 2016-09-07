# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"
  $count = 0

  def collect_all
    save_all
    @words = Word.all
  end

  def jlpt_collect
    @id = 3601
    begin 
      # JlptWord.all.each { |w|
      #   puts $count
      #   if w.raw.blank?
      #     save_jlpt_raw(w)
      #     sleep 5
      #   else
      #     $count = $count + 1
      #   end
      # }
      $count = 0

      JlptKanji.where("id >= ?", @id).each { |w|
        puts $count
        if w.raw.blank?
          next if w.id == 2217
          next if w.id == 2650
          next if w.id == 2745
          next if w.id == 3177
          next if w.id == 3479
          next if w.id == 3524
          next if w.id == 3555
          next if w.id == 3601
          save_kanji_raw(w)
          @id = w.id
          sleep 5
        else
          $count = $count + 1
        end
      }
    rescue
      sleep 15
      @id += 1
      retry
    end
    puts "SUCCESFUL"
  end

  def fix_unicode_insert
    wrong_list = JlptKanji.where("raw is null").map(&:kanji)
    @list = []
    wrong_list.each do |kanji|
      url = Addressable::URI.parse("http://mazii.net/api/mazii/#{kanji}/10").normalize.to_str
      puts "send request #{kanji}"
      res = RestClient.get(url)
      if res.code == 200
        json = ActiveSupport::JSON.decode(res)
        
        @list << json.to_json
        $count += 1
        puts "Save kanji #{$count} #{kanji}"
      end
    end
    File.open("raw_data/wrong_format_kanji/list", 'w') do |f2|
      @list.each do |line|
        f2.puts line
      end
    end
  end

  def insert_wrong_format
    wrong_list = JlptKanji.where("raw is null")
    index = 0
    File.open("raw_data/wrong_format_kanji/list", 'r') do |f1|
      while line = f1.gets
        word = line.gsub("\n",'')
        wrong_list[index].raw = word.each_char.select{|c| c.bytes.count < 4}.join('')
        wrong_list[index].save!
        index += 1
      end
    end
  end

  def save_kanji_raw(word)
    kanji = word.kanji
    # http://mazii.net/api/mazii/%E9%81%B8/10
    url = Addressable::URI.parse("http://mazii.net/api/mazii/#{kanji}/10").normalize.to_str
    puts "send request #{kanji}"
    res = RestClient.get(url)
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count += 1
      puts "Save kanji #{$count} #{kanji}"
    end
  end

  def save_jlpt_raw(word, fix=false)
    kanji = word.word
    if fix
      url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{kanji}/ja/vi").normalize.to_str
    else
      url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
    end
    puts "send request #{kanji}"
    res = RestClient.get(url)
    @results = {}
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count = $count + 1
      puts "Save word #{$count} #{kanji}"
    end
  end

  def jlpt_insert
    1.upto(5) do |level|
      File.open("filtered_data/words/n#{level}", 'r') do |f1|
        while line = f1.gets
          word = line.gsub("\n",'')
          JlptWord.create!(word: word, level: level) if word.present?
        end
      end

      File.open("filtered_data/kanji/n#{level}", 'r') do |f2|
        while line = f2.gets
          word = line.gsub("\n",'')
          JlptKanji.create!(kanji: word, level: level) if word.present?
        end
      end
    end
  end

  def fix_302
    not_found_words = Word.all.select{|w| x = eval(w.raw); x["found"].nil?}
    count = 0
    not_found_words.each { |w|
      save_raw(w, true)
      sleep 2
    }
  end

  def search
  end

  def save_all
    puts "start save all"
    Word.all.each { |w|
      puts $count
      if w.raw.blank?
        save_raw(w)
        sleep 5
      else
        $count = $count + 1
      end
    }
  end

  def save_raw(word, fix=false)
    kanji = word.kanji
    if fix
      # url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{kanji}/ja/vi").normalize.to_str
      url = Addressable::URI.parse("http://jisho.org/api/v1/search/words?keyword=#{kanji}").normalize.to_str
    else
      url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
    end
    puts "send request #{word.kanji}"
    res = RestClient.get(url)
    @results = {}
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count = $count + 1
      puts "Save #{$count} #{word.kanji}"
    end
  end

  def filter
    1.upto(5) do |level|
      filter_kana(level)
    end
  end

  def filter_latin(level)
    File.open("raw_data/words/n#{level}", 'r') do |f1|
      File.open("filtered_data/words/n#{level}", 'w') do |f2|
        while line = f1.gets
          latin = line =~ /\w/
          puts "#{line} #{latin}"
          f2.puts line if latin == nil && line.present?
        end
      end
    end  
  end

  def only_kana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def filter_kana(level)
    File.open("raw_data/words/n#{level}", 'r') do |f1|
      File.open("filtered_data/words/n#{level}", 'w') do |f2|
        count = 0
        while line = f1.gets
          if count % 2 == 0
            f2.puts line 
            next if only_kana(line)
          end
          count += 1
        end
      end
    end  
  end

  def filter_kanji(level)
    File.open("raw_data/kanji/n#{level}", 'r') do |f1|
      File.open("filtered_data/kanji/n#{level}", 'w') do |f2|
        count = 0
        while line = f1.gets
          f2.puts line if count % 4 == 0
          count += 1
        end
      end  
    end  
  end
end
