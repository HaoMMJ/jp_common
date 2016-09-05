# -*- coding: utf-8 -*-
class ShowController < ApplicationController
  def common_list
  end
  # x = eval(JlptWord.offset(rand(JlptWord.count)).limit(1).first.raw)
  def create_meaning
    # binding.pry
    Word.all.each do |w|
      raw = eval(w.raw)
      if raw["found"]
        if is_hiragana(w.kanji)

        elsif is_katakana(w.kanji)
        else  
          # w.kana = raw["phonetic"].scan( /\p{Hiragana}+/ ).first
          # w.save!
          relates = raw["data"].select{|r| r["word"] == w.kanji && r["phonetic"].present? }



        end
      else
        puts "Later"
      end
    end
    
  end

  def is_hiragana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def is_katakana(w)
    !!(w =~ /\p{Katakana}+/)
  end

end