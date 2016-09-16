# -*- coding: utf-8 -*-
class FixController < ApplicationController

  def detect_vocabulary_error
    File.open("fix/vocabulary", 'w') do |f|
      Vocabulary.where("kanji is not null and kanji != '' and id > 2149").each do |w|
        next if w.kanji.blank?
        jp = w.kanji.scan(/([\p{Han}\p{Hiragana}～\(\)「」\[\]？｢｣0-9０１２３４５６７８９]+)/).uniq.flatten.first
        if jp.present? && jp != w.kanji
          if jp.strip! == w.kanji.strip!
            # w.kanji = w.kanji.strip!
            f.puts "#{w.id} #{w.kanji}        #{jp}"
          end
        end
      end
    end
  end

  def fix_vocabulary
    File.open("fix/vocabulary", 'r') do |f1|
      File.open("fix/filtered_vocabulary", 'w') do |f2|
        while line = f1.gets
          word = line.gsub("\n",'')
          id = word.scan(/\d+/).first
          fixed_word = word[/「(.*?)」/m, 1]
          # f2.puts "#{id} #{fixed_word.strip!}" if fixed_word.present?
          if fixed_word.present?
            recheck_words = Vocabulary.where("kanji = ?", fixed_word)
            if recheck_words.length > 0
              recheck_words.each do |cw|
                f2.puts "#{cw.id} #{id}"
              end
            else  
              vob = Vocabulary.find(id)
              vob.kanji = fixed_word
              vob.save!
            end
          end
        end
      end
    end
  end

  def manual_fix_vocabulary
    File.open("fix/vocabulary", 'r') do |f1|
      while line = f1.gets
        word = line.gsub("\n",'')
        id = word.scan(/\d+/).first
        fixed_word = word[/「(.*?)」/m, 1]
        if fixed_word.present?
          vob = Vocabulary.find(id)
          vob.kanji = fixed_word
          binding.pry
        end
      end
    end
  end
end