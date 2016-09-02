# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"
  $count = 0

  def collect_all
    save_all
    @words = Word.all
  end

  def save
    binding.pry
  end

  def fix_302
    not_found_words = Word.all.select{|w| x = eval(w.raw); x["status"] == 302}
    count = 0
    not_found_words.each { |w|
      save_raw(w, true)
      # sleep 5
    }
  end

  def search
  end

  def save_all
    puts "start save all"
    Word.all.each { |w|
      puts $count
      if w.raw.blank?
        sleep 5
        save_raw(w)
      else
        $count = $count + 1
      end
    }
  end

  def save_raw(word, fix=false)
    kanji = word.kanji
    if fix
      url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{kanji}/ja/vi").normalize.to_str
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
    # 1.upto(5) do |level|
    #   filter_words(level)
    #   filter_kanji(level)
    # end
    filter_words 5
  end

  def filter_words(level)
    File.open("raw_data/words/n#{level}", 'r') do |f1|
      File.open("filtered_data/words/n#{level}", 'w') do |f2|
        while line = f1.gets
          latin = line =~ /\w/
          puts "#{line} #{latin}"
          f2.puts line if latin == nil && latin.present?
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
