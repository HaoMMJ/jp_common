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
    list = detect_japanese(params["search_text"])
    list.each do |w|
      word      = w[0]
      # kana      = w[1]
      # word_type = w[2]
      jishokei  = w[3]
      found_word = search_vocabulary(jishokei)
      words << found_word_json(found_word, word)
    end 

    render json: { 
      word_list: words.sort_by { |w| -w[:origin].length }
    }
  end

  def found_word_json(w, o)
    { 
      id: w.try(:id),
      word: w.try(:kanji),
      kana: w.try(:kana),
      cn_mean: w.try(:cn_mean),
      mean: w.try(:mean),
      level: w.try(:level),
      origin: o
    }
  end
end