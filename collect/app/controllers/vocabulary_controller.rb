# -*- coding: utf-8 -*-
class VocabularyController < ApplicationController

  def filter_full_dictionary
    collect = []

    File.open("raw_data/full_dictionary/hiragana", 'r') do |f1|
      File.open("filtered_data/dictionary/hiragana", 'w') do |f2|
        while line = f1.gets
          # words = line.scan(/「 (.*?) 」/).flatten
          line_content = line.split('##')[1]
          next if line_content.blank?
          content = line_content.split('#')
          # next unless content[0].japanese?
          original_word = content[0].split("  ")
          hiragana = original_word[0]
          kanji    = original_word[1]
          kanji    = kanji.present? ? kanji.scan(/「 (.*?) 」/).flatten.first : ""
          meanings = content[1].scan(/\|=(.*?)\|/).flatten.reject{|c| c.blank?}
          first_word = {}
          first_word[:hiragana] = hiragana
          first_word[:kanji]    = kanji
          first_word[:meanings] = []
          is_first_word = true
          temp_word = {}
          temp_word[:meanings] = []
          next_words = []

          meanings.each.with_index(1) do |word, index|
            check_kanji = word =~ /「(.*)」/
            if !!(check_kanji)
              is_first_word = false
            end
            if is_first_word
              first_word[:meanings] << word
            else
              if(!!check_kanji)
                temp_word[:kanji] = word.scan(/「 (.*?) 」/).flatten.first
                temp_word[:hiragana] = (check_kanji > 0) ? word.split("  ")[0] : hiragana
              else
                temp_word[:meanings] << word
              end
              if index == meanings.length || !!(meanings[index] =~ /「(.*)」/)
                next_words << temp_word
                temp_word = {}
                temp_word[:meanings] = []
              end
            end
          end

          calculation_words = [first_word, next_words].flatten
          calculation_words.each do |w|
            output_txt = "#{w[:kanji]}    #{w[:hiragana]}    #{w[:meanings].join('|')}"
            f2.puts output_txt
          end
        end
      end
    end
  end

  def filter_katakana
    collect = []
    count = 1
    File.open("raw_data/full_dictionary/katakana", 'r') do |f1|
      File.open("filtered_data/dictionary/katakana", 'w') do |f2|
        while line = f1.gets
          line_content = line.split('#')
          words = line_content[2].split("  ")
          meanings = line_content[3].split("|=").map{|s| s.strip}.select{|m| m.present?}
          if words.length > 1
            collect << [words, count].flatten
          end

          f2.puts "#{words[0]}_#{words[1]}_#{meanings[0]}    #{meanings[1..-1].join("    ")}"
          count += 1
        end
      end
    end
    File.open("filtered_data/dictionary/check_dup_katakana", 'w') do |f3|
      means = collect.map{|w| w[1]}
      collect.each do |w|
        word = w[0]
        if means.include? word
          f3.puts "#{w[0]} #{w[1]} #{w[2]} #{means.detect{|x| x == word}}"
        end
      end
    end
  end

  def filter_duplicate_hiragana
    kanji_list = []
    kana_list  = []
    lines      = []
    count = 1
    File.open("filtered_data/dictionary/hiragana", 'r') do |f1|
      while line = f1.gets
        content = line.split("    ")
        kanji = content[0]
        kana  = content[1]
        if kanji.present? || kana.present?
          kanji_list << kanji
          kana_list  << kana
          lines << count
        end
        count += 1
      end
    end

    if kana_list.length == kana_list.length
      File.open("filtered_data/dictionary/duplicate", 'w') do |f2|
        kanji_list.each.with_index(0) do |k, index|
          if kana_list.include?(k) && k.hiragana?
            f2.puts "#{k} #{kana_list[index]} #{lines[index]}"
          end
        end
      end
    end
  end

  def last_filter_hiragana
    duplicate_words = []
    File.open("filtered_data/dictionary/duplicate", 'r') do |f|
      while line = f.gets
        kana = line.split(" ")[0]
        duplicate_words << kana
      end
    end

    File.open("filtered_data/dictionary/hiragana", 'r') do |f1|
      File.open("filtered_data/dictionary/last_hiragana", 'w') do |f2|
        while line = f1.gets
          content = line.split("    ")
          kanji = content[0]
          unless duplicate_words.include? kanji
            f2.puts line
          end
        end
      end
    end
  end

  def insert_hiragana
    count = 0
    ActiveRecord::Base.transaction do
      File.open("filtered_data/dictionary/used_hiragana", 'r') do |f|
        while line = f.gets
          content = line.split("    ")
          kanji = content[0]
          kana  = content[1]
          raw = content[2]
          vocab = Vocabulary.where("kanji = ? and kana = ?", kanji, kana).first
          if vocab.blank?
            vocab = Vocabulary.new
            vocab.kanji = kanji
            vocab.kana  = kana
            vocab.raw   = raw
            vocab.level = 1
            vocab.from_source = "full_dictionary"
            vocab.save!
          else
            if vocab.raw.blank?
              vocab.raw = raw
              vocab.save!
            end
          end
          puts count
          count += 1
        end
      end
    end
  end

  def insert_missing_raw
    count = 0
    ActiveRecord::Base.transaction do
      File.open("filtered_data/dictionary/used_hiragana", 'r') do |f|
        while line = f.gets
          content = line.split("    ")
          kanji = content[0]
          kana  = content[1]
          raw = content[2]
          vocab = Vocabulary.where("kanji = ? and kana = ? and raw is null", kanji, kana).first
          if vocab.present? && raw.present?
            vocab.raw = raw
            vocab.save!
          end
        end
      end
    end
  end

  def insert_hiragana_meaning
    count = 0
    ActiveRecord::Base.transaction do
      vocabs = Vocabulary.where("raw is not null")
      vocabs.each do |v|
        means = v.raw.split("|")  
        temp_mean = []
        temp_sentences = []
        temp_means = []
        is_sentence = false
        means.each.with_index(1) do |m, index|
          if contains_japanese(m)
            is_sentence = true
            temp_sentences << m
          else
            if is_sentence == true
              mean = Mean.create!(vocabulary_id: v.id, content: temp_mean.join(","))
              temp_sentences.each do |s|
                cont = s.split(":")
                Sentence.create!( mean_id: mean.id, content: cont[0], translation: cont[1])
              end
              # temp_means << [temp_mean, temp_sentences]
              temp_mean = []
              temp_sentences = []
              finish_collect = false
            end
            if !is_lower(m)
              # v.cn_mean = m.scan(/[[:word:]]+/u).first
              # v.save!
              next
            else
              temp_mean << m
            end
            is_sentence = false
          end
          if index == means.length 
            mean = Mean.create!(vocabulary_id: v.id, content: temp_mean.join(","))
            temp_sentences.each do |s|
              cont = s.split(":")
              Sentence.create!( mean_id: mean.id, content: cont[0], translation: cont[1])
            end
            
            # binding.pry if count == 2
            # temp_means << [temp_mean, temp_sentences]
            temp_mean = []
            temp_sentences = []
            finish_collect = false
          end
        end
        puts count
        count += 1
        # if v.id == 646
        #   binding.pry
        #   break
        # end
      end
    end
  end

  def update_hiragana_meaning
    vobs = Vocabulary.where("mean is null or mean = ''")
    vobs.each do |v|
      means = v.means.map(&:content)
      v.mean = means.join("; ")
      v.save!
    end
  end

  def remove_hiragana_duplicate
    a = Vocabulary.where("kanji is not null and kanji != ''").map(&:kanji).select{|v| v.present?}
    w = a.select{|w| a.count(w) > 1}
    x = []
    y = []
    count = 0
    w.each do |z|
      l = Vocabulary.where("kanji = ?", z)
      if l.length == 2 && l[0].kana != l[1].kana
        x << z
      elsif l.length == 3 && l[0].kana != l[1].kana && l[1].kana != l[2].kana && l[0].kana != l[2].kana
        x << z
      end
      # puts count
      # count += 1
    end 
    count = 0
    puts "start"
    n = w - x
    binding.pry
    m = n.select{|v| l = Vocabulary.where("kanji = ?", v); l.map(&:kana).uniq.length != l.length}
    m.each do |v|
      # binding.pry
      # l = Vocabulary.where("kanji = ?", v)
      # if l.length == 2 && l[0].kana == l[1].kana && l[0].kanji == l[1].kanji && l[0].mean == l[1].mean
      #   if l[0].raw.present?
      #     l[1].destroy
      #   else
      #     l[0].destroy
      #   end
      # end
      puts count
      binding.pry
      count+=1
    end 
  end


  def fix_blank_kana
    k = Vocabulary.where("kana is null or kana = ''").map(&:kanji).uniq
    need_check = []
    recheck = []
    ActiveRecord::Base.transaction do
      k.each do |w|
        vs = Vocabulary.where(kanji: w)
        keep = vs.detect{|x| x.kana.present?}
        if vs.length > 1 && keep.present?
          vs.each do |nr|
            if nr.id != keep.id && nr.kana.blank?
              nr.destroy
            end
          end
        else
          need_check << w
        end
      end

      tagger = MeCab::Tagger.new
      need_check.each do |w|
        text = tagger.parse(w)
        lines = text.split("\n")
        if lines.length == 2
          kana = lines.first.split(",")[-2].hiragana
          vocabs = Vocabulary.where("kanji = ?", w)
          vocabs.each do |x|
            if kana.blank?
              x.kana = kana
              x.save!
            end
          end
        else
          recheck << w
        end
      end

      binding.pry
    end
  end

  def update_vocabulary_level
    ActiveRecord::Base.transaction do
      JlptWord.all.each do |w|
        word = w.word
        level = w.level
        kana = w.reading
        if only_kana(word)
          vocabs = Vocabulary.where("(kanji is null or kanji = '') and kana = ?", kana)
        else
          vocabs = Vocabulary.where("(kanji = ? and kana = ?", word, kana)
        end  
        binding.pry if vocabs.length == 0
        vocabs.each do |v|
          v.level = level
          v.save!
        end
      end

      binding.pry

      JlptKanji.all.each do |k|
        kanji = k.kanji
        level = k.level
        vocabs = Vocabulary.where("(kanji = ?", kanji)
        binding.pry if vocabs.length == 0
        vocabs.each do |v|
          v.level = level
          v.save!
        end
      end
    end
  end

  def update_vocabulary_kanji
    vocabs = Vocabulary.where("kanji is not null and kanji != ''")
    vocabs.each do |w|
      w.cn_mean = get_kanji_mean(kanji)
      w.save!
    end
  end
end
