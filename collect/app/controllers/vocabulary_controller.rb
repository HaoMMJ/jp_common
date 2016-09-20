# -*- coding: utf-8 -*-
class VocabularyController < ApplicationController
  
  def filter_full_dictionary
    collect = []
    File.open("raw_data/full_dictionary/hiragana", 'r') do |f1|
      File.open("filtered_data/dictionary/hiragana", 'w') do |f2|
        while line = f1.gets
          words = line.scan(/「 (.*?) 」/).flatten
          words.each do |w|
            # f2.puts w
            collect << w
          end
          # binding.pry
          # break
        end
        vobs = Vocabulary.all.map(&:kanji)
        special = vobs.compact.uniq - collect.uniq
        special.each do |kanji|
          f2.puts kanji
        end
      end
    end
  end
end
