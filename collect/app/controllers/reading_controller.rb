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
    text = params["search_text"]
    kanji_list = text.scan(/\p{Han}+/).uniq
    words = []
    vocabs = []
    kanji_list.each do |k|
      found_words = Vocabulary.where("kanji like ?", "%#{k}%").order(:kanji).first
      vocabs << [found_words, k] if found_words.present?
    end
    vocabs.each do |w, o|
      words << { 
        id: w.id,
        word: w.kanji,
        kana: w.kana,
        cn_mean: w.cn_mean,
        mean: w.mean,
        level: w.level,
        origin: o
      }
    end
    render json: { 
      word_list: words
    }
  end
end