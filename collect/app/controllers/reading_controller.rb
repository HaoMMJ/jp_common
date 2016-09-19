# -*- coding: utf-8 -*-
class ReadingController < ApplicationController
  def create_course_form
  end

  def create_course
  end

  def update_course_form
  end

  def update_course
  end

  def create_lession_form
  end

  def create_lession
  end

  def update_lession_form
  end

  def update_lession
  end

  def auto_translate_form
  end

  def auto_translate
    words = []
    vocabs = []
    text = params["search_text"]
    kanji_list = text.scan(/\p{Han}+/).uniq
    kanji_list.each do |k|
      if k.length > 3
        kanji_meanings = []
        kana_list      = []
        k.split("").each do |kc|
          kanji = KanjiDictionary.where(kanji: kc).first
          kanji_meanings << kanji.kanji_mean if kanji.present?
          kana_list << kanji.onyomi.split(",").first if kanji.present?
        end
        found_word = Vocabulary.new(kana: kana_list.join(""), mean: kanji_meanings.join(" "))
        vocabs << [found_word, k]
      else  
        found_word = Vocabulary.where("kanji = ?", "#{k}").first
        found_word = Vocabulary.where("kanji like ?", "#{k}%").order(:kanji).first if found_word.blank?
        vocabs << [found_word, k]# if found_words.present?
      end  
    end

    # Should detect only adverb
    # hiragana_list = text.scan(/\p{Hiragana}+/).uniq
    # hiragana_list.each do |k|
    #   found_words = Vocabulary.where("kana = ?", "#{k}").first
    #   vocabs << [found_words, k]# if found_words.present?
    # end

    katakana_list = text.scan(/[\p{Katakana}卜ー]+/).uniq
    katakana_list.each do |k|
      found_words = Vocabulary.where("kana = ?", "#{k}").first
      vocabs << [found_words, k]# if found_words.present?
    end

    vocabs.each do |w, o|
      words << { 
        id: w.try(:id),
        word: w.try(:kanji),
        kana: w.try(:kana),
        cn_mean: w.try(:cn_mean),
        mean: w.try(:mean),
        level: w.try(:level),
        origin: o
      }
    end
    
    render json: { 
      word_list: words.sort_by { |w| -w[:origin].length }
    }
  end
end