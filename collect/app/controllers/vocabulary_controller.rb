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

          
          # f2.puts "#{count}" if !is_lower(meanings[0])
          mean_list = meanings[1..-1].select{|m| m.split("|+").length == 1}
          examples  = meanings[1..-1].select{|m| m.split("|+").length > 1}
          means = [meanings[0], mean_list].flatten.join("; ")
          f2.puts "#{words[0]}_#{words[1]}_#{means}    #{examples.join("    ")}"
          # f2.puts "#{mean_list.join('    ')} #{count}" if mean_list.present?
          # f2.puts "#{meanings[0]} #{count}" if meanings[0].length < 5
          count += 1
        end
      end
    end
    File.open("filtered_data/dictionary/check_dup_katakana", 'w') do |f3|
      means = collect.map{|w| w[1]}
      collect.each do |w|
        word = w[0]
        if means.include? word
          f3.puts w[2]
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

  def insert_katakana
    count = 0
    ActiveRecord::Base.transaction do
      File.open("filtered_data/dictionary/katakana", 'r') do |f|
        while line = f.gets
          content = line.split("    ")
          mean = content[0].split("_").select{|x| x.present?}
          examples = content[1..-1]
          if mean.length > 2
            if mean[0].contains_kanji?
              word = mean[0]
              reading = mean[1]
            else
              word = mean[1]
              reading = mean[0]
            end
            meaning = mean[2].strip

            vocab = Vocabulary.where("kanji = ? and kana = ?", word, reading).first
            vocab = Vocabulary.new if vocab.blank?
            vocab.kanji = word
            vocab.kana  = reading
            vocab.cn_mean = get_kanji_mean(word)
            vocab.mean = meaning
            vocab.save!
          else
            vocab = Vocabulary.where("kana = ?", mean[0]).first
            vocab = Vocabulary.new if vocab.blank?
            vocab.kana  = mean[0]
            vocab.mean = mean[1].strip
            vocab.save!
          end

          new_mean = Mean.new
          new_mean.vocabulary_id = vocab.id
          new_mean.content = meaning
          new_mean.save!

          examples.each do |e|
            next if e.strip.blank?
            example_content = e.split("|+")
            sentence = Sentence.new
            sentence.mean_id = new_mean.id
            sentence.content = example_content[0].strip
            binding.pry if example_content[1].blank?
            sentence.translation = example_content[1].strip
            sentence.save!
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
      File.open("filtered_data/not_found/jlpt", 'w') do |f2|
        JlptWord.where("level > 1").each do |w|
          word = w.word
          level = w.level
          kana = w.reading
          unless word.present?
            vocabs = Vocabulary.where("(kanji is null or kanji = '') and kana = ?", kana)
          else
            vocabs = Vocabulary.where("kanji = ? and kana = ?", word, kana)
          end  
          f2.puts "#{word}    #{kana}    #{level}" if vocabs.length == 0
          vocabs.each do |v|
            v.level = level
            v.save!
          end
        end

        JlptKanji.where("level > 1").each do |k|
          kanji = k.kanji
          level = k.level
          vocabs = Vocabulary.where("kanji = ?", kanji)
          f2.puts "#{kanji}    #{level}"  if vocabs.length == 0
          vocabs.each do |v|
            v.level = level
            v.save!
          end
        end
      end
    end
  end

  def update_vocabulary_kanji
    ActiveRecord::Base.transaction do
      vocabs = Vocabulary.where("kanji is not null and kanji != ''")
      vocabs.each do |w|
        next unless w.kanji.contains_kanji?
        w.cn_mean = get_kanji_mean(w.kanji)
        w.save!
      end
    end
  end

  def insert_missing_jlpt_kanji
    kanjis = ["設","査","営","輸","述","復","移","含","況","専","効","捜","療","採","競","販","般","貿","換","暴","均","圧","爆","固","囲","承","患","絡","募","績","貨","混","宇","震","触","汚","複","郵","燃"," 包","紹","雇","替","預","簡","贈","悩","貯","硬","埋","柔","濃","幼","甘","臣","浅","掃","掘","捨","軟","沈","凍","郊","踊","械","喫","干","刷","溶","鉱","鋭","塗","叫","拝","祈","湿","咲","召","蒸","鈍","磨","膚","濯","沸","菓","枯","憎","肯","燥","畜","挟","伺","決","取","支","交","予","告","認","引","求","示","確","容","必","演"," 争","置","疑","放","与","構","違","規","備","警","落","退","識","呼","突","存","殺","破","降","責","捕","危","迎","亡","返","険","頼","途","許","抜","努","散","浮","絶","押","倒","払","徒","遅","居","招","困","賛","抱","恐","遠","戻","互","似","探","逃","遊","迷","閉","暮","悲","到","盗","吸","忘","吹","洗","慣","貧","怒","疲","鳴"," 眠","怖","忙","偉","以","思","送","究","待","試","映","験","仕","去","走","習","借","曜","飲","見","聞","読"]
    ActiveRecord::Base.transaction do
      kanjis.each do |k|
        k = k.strip
        kanji = KanjiDictionary.where("kanji = ?", k).first
        binding.pry if kanji.nil?
        vocab = Vocabulary.where("kanji = ?", k).first
        if vocab.present?
          binding.pry
        else
          vocab = Vocabulary.new
          vocab.kanji = k
          vocab.kana  = kanji.onyomi
          vocab.cn_mean = kanji.kanji_mean
          vocab.mean = kanji.mean
          level = JlptKanji.where("kanji = ?", k).first.try(:level) || 1
          vocab.level = level
          vocab.from_source = "full_dictionary"
          vocab.save!
        end
      end
    end
  end

  def insert_jlpt_kana_without_kanji
    kanas = ["それぞれ","あいかわらず","あいまい","あかんぼう","あきれる","あくび","あたりまえ","あちらこちら","あてはまる","あてはめる","あぶる","あふれる","あらすじ","あれこれ","あわただしい","あわてる","いきなり","いちいち","いってらっしゃい","いってまいります","いつのまにか","いよいよ","うどん","おおざっぱ","オーバーコート","おかけください","おきのどくに","おくさん","おげんきで","おさきに","おしゃれ","おじゃまします","おだいじに","おどかす","おととい","おねがいします","おはよう","おまたせしました","おまちどおさま","おめでたい","おやすみ","かじる","かゆい","からかう","かるた","かわいがる","きっかけ","くしゃみ","くたびれる","くだらない","くっつく","くっつける","くどい","くるむ","くれぐれも","ごくろうさま","こしらえる","こぼす","こぼれる","こらえる","こんばんは","さきおととい","さようなら","さわやか","しあさって","しっぽ","しびれる","しぼむ","しゃっくり","じゃんけん","じゅうたん","しょうがない","ずうずうしい","すくなくとも","すっぱい","すまない","すれちがう","ぜひとも","そういえば","そうして","そのころ","そのため","そのほか","だいいち","ダイヤグラム","たちまち","だます","ためらう","ちぎる","ついで","つまずく","でたらめ","どうぞよろしく","とっくに","どなる","ともかく","なぐる","なにしろ","なんとも","ねじ","のこぎり","ばからしい","はじめまして","ばね","はめる","ひとまず","ひとりでに","ひゃっかじてん","ふざける","ぶつける","ぶつぶつ","ぶらさげる","へそ","へる","ほどく","ぼろ","またぐ","まぶしい","まぶた","みじめ","みっともない","めちゃくちゃ","めでたい","めまい","もしかすると","もたれる","もったいない","やかましい","やたらに","やっつける","やっぱり","やむをえない","ゆでる","よこす","ローマじ","わりあいに","あいにく","あした","あちこち","あらゆる","ありがとう","あるいは","あんまり","よい","いえ","いえ","いずれ","いたずら","いち","いつまでも","いつも","いつも","いらいら","いわゆる","うがい","うなる","おしゃべり","おそらく","おまえ","おめでとう","おや","およそ","かもしれない","かわいそう","かわいらしい","ごめんなさい","こんにちは","さて","しかも","しきりに","したがって","したがって","しばしば","しまう","しゃべる","すなわち","そこで","そのうち","そのまま","それと","それとも","ただ","たとえ","たびたび","たまらない","ちょうだい","つまり","できる","できれば","どうか","どうしても","ところが","とにかく","とん","なお","なぜなら","なにも","ね","ノー","はさみ","ふと","ほぼ","まさか","まさに","ますます","まるで","もしも","やがて","やはり","やや","ヨーロッパ","よろしく","わがまま","わざと","あかちゃん","あげる","いじめる","いただく","いっぱい","うかがう","えんりょする","おいでになる","おかげ","おっしゃる","おつり","かっこう","おかねもち","かまう","くださる","くれる","けんか","こう","ごちそう","このあいだ","ごらんになる","しかる","しっかり","じゃま","すく","すり","ぜひ","ぜんぜん","それほど","そろそろ","つき","つもり","とうとう","とこや","なさる","なるべく","なるほど","ぬれる","ねだん","ねっしん","のど","はず","ひげ","ぶどう","ほめる","または","もっとも","もらう","やはり","やっぱり","よろしい","あさって","あなた","あびる","よい","いかが","いつ","いつも","おなか","おまわりさん","かかる","かぎ","かける","すぐに","そうして","そば","たぶん","ちゃわん","つける","できる","どなた","など","なる","なに","はく","ふろ","ほか","ラジオカセット"]
    File.open("filtered_data/not_found/check_jlpt_kana", 'w') do |f|
      kanas.each do |k|
        vocab = Vocabulary.where("kana = ?", k).first
        if vocab.present?
          f.puts "#{k}    #{vocab.mean}"
        else
          binding.pry
        end
      end
    end
  end
end
