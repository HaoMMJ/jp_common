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
end
