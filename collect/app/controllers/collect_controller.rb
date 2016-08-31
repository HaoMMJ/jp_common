# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"
  $count = 0

  def index
    save_all
    @words = Word.all
  end

  def save_all
    Word.all.each { |w|
      sleep 10
      if w.raw.blank?
        save_raw(w)
      else
        $count = $count + 1
      end  
    }
  end

  def save_raw(word)
    kanji = word.kanji
    url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
    res = RestClient.get(url)
    @results = {}
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count = $count + 1
      puts "Save #{$count} #{word}"
    end
  end
end
