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

  def auto_translate_1
    text = params["search_text"]
    words = []
    Vocabulary.all.each do |w|
      if w.kanji.present? && text.include?(w.kanji)
        words << { 
          id: w.id
          word: w.kanji,
          kana: w.kana,
          cn_mean: w.cn_mean,
          mean: w.mean,
          level: w.level
        }
      end
    end
    render json: { 
      word_list = words
    }
  end

  def auto_translate
    text = params["search_text"]
    kanji_list = text.scan(/\p{Han}+/).uniq
    words = []
    vocabs = Vocabulary.where("kanji ILIKE ANY ( array[?] )", kanji_list.map {|val| "%#{val}%" })
    vocabs.each do |w|
      words << { 
        id: w.id
        word: w.kanji,
        kana: w.kana,
        cn_mean: w.cn_mean,
        mean: w.mean,
        level: w.level
      }
    end
    render json: { 
      word_list = words
    }
  end
end