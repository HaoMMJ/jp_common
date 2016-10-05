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

  def search_word
    search_word = params["search_word"]
    found_word = search_vocabulary(search_word)
    render json: { 
      word: found_word_json(found_word, search_word)
    }
  end

  def convert_ppm_to_jpg
    records = Dir.glob("./lession/*")
    records.each.with_index(1) do |f, index|
      system "convert -verbose -density 150 -trim #{f} -quality 100 -flatten -sharpen 0x1.0 lession_#{index}.jpg"
    end
  end
end