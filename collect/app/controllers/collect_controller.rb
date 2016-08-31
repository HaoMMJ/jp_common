# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"

  def index
    Word.all.each { |w|
      sleep 10
      save_raw(w) if w.raw.blank?
    }

    @words = Word.all
  end
  $count = 0
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
