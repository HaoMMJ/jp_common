# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"
  $count = 0

  def index
    save_all
    @words = Word.all
  end

  def save
    binding.pry
  end

  def save_all
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

  def save_raw(word)
    kanji = word.kanji
    url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
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
