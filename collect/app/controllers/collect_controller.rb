# -*- coding: utf-8 -*-
class CollectController < ApplicationController
  require "addressable/uri"
  $count = 0

  def fix_raw_dictionary_source
    RawDictionary.all.each do |w|
      h = eval(w.raw)
      if h["found"] == false
        json = search_from_jisho(w.word)
        if json.blank?
          data = search_from_google(params['word'])
          w.raw = data
          w.source = 'google'
          w.save!
        else
          w.raw = json
          w.source = 'jisho'
          w.save!
        end
        sleep 5
      end
    end
  end

  def import_kanji_dictionary
    # File.open("filtered_data/kanji/yoyo_kanji", 'r') do |f|
    #   while line = f.gets
    #     r = line.split("    ")
    #     KanjiDictionary.create!(kanji: r[1], kanji_mean: r[2], mean: r[3], onyomi: r[4])
    #     # puts "#{r[0]}, #{r[1]}, #{r[2]}, #{r[3]}, #{r[4]}}"
    #   end
    # end

    KanjiDictionary.all.each do |w|
      w.onyomi = romaji_to_kana(w.onyomi.gsub("\n",''))
      w.save!
    end
  end

  def collect_all
    save_all
    @words = Word.all
  end

  def jlpt_collect
    @id = 3601
    begin 
      # JlptWord.all.each { |w|
      #   puts $count
      #   if w.raw.blank?
      #     save_jlpt_raw(w)
      #     sleep 5
      #   else
      #     $count = $count + 1
      #   end
      # }
      $count = 0

      JlptKanji.where("id >= ?", @id).each { |w|
        puts $count
        if w.raw.blank?
          next if w.id == 2217
          next if w.id == 2650
          next if w.id == 2745
          next if w.id == 3177
          next if w.id == 3479
          next if w.id == 3524
          next if w.id == 3555
          next if w.id == 3601
          save_kanji_raw(w)
          @id = w.id
          sleep 5
        else
          $count = $count + 1
        end
      }
    rescue
      sleep 15
      @id += 1
      retry
    end
    puts "SUCCESFUL"
  end

  def fix_unicode_insert
    wrong_list = JlptKanji.where("raw is null").map(&:kanji)
    @list = []
    wrong_list.each do |kanji|
      url = Addressable::URI.parse("http://mazii.net/api/mazii/#{kanji}/10").normalize.to_str
      puts "send request #{kanji}"
      res = RestClient.get(url)
      if res.code == 200
        json = ActiveSupport::JSON.decode(res)
        
        @list << json.to_json
        $count += 1
        puts "Save kanji #{$count} #{kanji}"
      end
    end
    File.open("raw_data/wrong_format_kanji/list", 'w') do |f2|
      @list.each do |line|
        f2.puts line
      end
    end
  end

  def insert_wrong_format
    wrong_list = JlptKanji.where("raw is null")
    index = 0
    File.open("raw_data/wrong_format_kanji/list", 'r') do |f1|
      while line = f1.gets
        word = line.gsub("\n",'')
        wrong_list[index].raw = word.each_char.select{|c| c.bytes.count < 4}.join('')
        wrong_list[index].save!
        index += 1
      end
    end
  end

  def save_kanji_raw(word)
    kanji = word.kanji
    # http://mazii.net/api/mazii/%E9%81%B8/10
    url = Addressable::URI.parse("http://mazii.net/api/mazii/#{kanji}/10").normalize.to_str
    puts "send request #{kanji}"
    res = RestClient.get(url)
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count += 1
      puts "Save kanji #{$count} #{kanji}"
    end
  end

  def save_jlpt_raw(word, fix=false)
    kanji = word.word
    if fix
      url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{kanji}/ja/vi").normalize.to_str
    else
      url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
    end
    puts "send request #{kanji}"
    res = RestClient.get(url)
    @results = {}
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count = $count + 1
      puts "Save word #{$count} #{kanji}"
    end
  end

  def jlpt_insert
    1.upto(5) do |level|
      File.open("filtered_data/words/n#{level}", 'r') do |f1|
        while line = f1.gets
          word = line.gsub("\n",'')
          JlptWord.create!(word: word, level: level) if word.present?
        end
      end

      File.open("filtered_data/kanji/n#{level}", 'r') do |f2|
        while line = f2.gets
          word = line.gsub("\n",'')
          JlptKanji.create!(kanji: word, level: level) if word.present?
        end
      end
    end
  end

  def fix_302
    not_found_words = Word.all.select{|w| x = eval(w.raw); x["found"].nil?}
    count = 0
    not_found_words.each { |w|
      save_raw(w, true)
      sleep 2
    }
  end

  def fix_not_found
    ids = Meaning.all.map(&:word_id).uniq.compact
    ws  = Word.where("id not in (?)", ids).select{|w| 
      raw = eval(w.raw); 
      if raw["found"] == false && !is_hiragana(w.kanji)
        save_raw(w, true)
      end
      sleep 2
    }
  end

  def search
  end

  def save_all
    puts "start save all"
    Word.all.each { |w|
      puts $count
      if w.raw.blank?
        save_raw(w)
        sleep 5
      else
        $count = $count + 1
      end
    }
  end

  def save_raw(word, fix=false)
    kanji = word.kanji
    if fix
      # url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{kanji}/ja/vi").normalize.to_str
      url = Addressable::URI.parse("http://jisho.org/api/v1/search/words?keyword=#{kanji}").normalize.to_str
    else
      url = Addressable::URI.parse("http://mazii.net/api/search/#{kanji}/10/1").normalize.to_str
    end
    puts "send request #{word.kanji}"
    res = RestClient.get(url)
    @results = {}
    if res.code == 200
      json = ActiveSupport::JSON.decode(res)
      word.raw = json
      word.save!
      $count = $count + 1
      puts "Save #{$count} #{word.kanji}"
    end
  end

  def filter
    1.upto(5) do |level|
      filter_kana(level)
    end
  end

  def filter_latin(level)
    File.open("raw_data/words/n#{level}", 'r') do |f1|
      File.open("filtered_data/words/n#{level}", 'w') do |f2|
        while line = f1.gets
          latin = line =~ /\w/
          puts "#{line} #{latin}"
          f2.puts line if latin == nil && line.present?
        end
      end
    end  
  end

  def only_kana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def filter_kana(level)
    File.open("raw_data/words/n#{level}", 'r') do |f1|
      File.open("filtered_data/words/n#{level}", 'w') do |f2|
        count = 0
        while line = f1.gets
          if count % 2 == 0
            f2.puts line 
            next if only_kana(line)
          end
          count += 1
        end
      end
    end  
  end

  def filter_kanji(level)
    File.open("raw_data/kanji/n#{level}", 'r') do |f1|
      File.open("filtered_data/kanji/n#{level}", 'w') do |f2|
        count = 0
        while line = f1.gets
          f2.puts line if count % 4 == 0
          count += 1
        end
      end  
    end  
  end

  def common_list
    word_ids = Meaning.all.map(&:word_id).compact.uniq
    @words   = Word.includes(:meanings).where('id in (?)', word_ids)
    hiragana_filtered_list = ["する", "から", "こと", "よる", "など", "この", "その", "まで", "もの", "これ", "よう", "より", "おく", "でも", "それ", "しかし", "つく", "のみ", "なお", "および", "だけ", "そして", "ながら", "それぞれ", "うち", "かつて", "ここ", "そこ", "ところ", "または", "ほぼ", "あるいは", "しか", "いずれ", "まま", "このよう", "そのまま", "つつ", "すぐ", "やる", "もう", "いわゆる", "しばしば", "まだ", "また", "なる", "きっかけ", "どう", "かなり", "すなわち", "だろう", "なら", "べき", "わけ", "かつ", "やや", "どちら", "やがて", "ちなみに", "らしい", "くらい", "ばかり", "もしくは", "しかしながら", "こちら", "もたらす", "そう", "むら", "こう", "こそ", "どの", "よす", "どこ", "つまり", "こうして", "ところが", "さえ", "そんな", "あらゆる", "かも", "ようやく", "やはり", "あなた", "ないし", "どのよう", "すら", "こなす", "たばこ", "もし", "かい", "しかも", "もちろん", "なり", "やってくる", "もっと", "さくら", "あくまで", "すずき", "とても", "どれ", "あの", "みどり", "とりわけ", "いまだ", "さようなら", "ならびに", "それほど", "なかなか", "たけし", "ずれる", "ずっと", "そもそも", "つぐ", "ため", "もはや", "じゃ", "したためる", "せい", "よって", "くぐる", "ない", "どのように", "どんな", "いけない", "りす", "いう", "いまだに", "たび", "いつ", "すると", "いかなる", "おおよそ", "あくまでも", "ひどい", "もっとも", "けど", "ひれ", "あまり", "いきなり", "とる", "ゆっくり", "たとえ", "おはよう", "うどん", "さほど", "きりん", "まるで"]
    File.open("quizlet/common/10000", 'w') do |f|
      @words.all.each do |w|
        line = ""
        if (is_hiragana(w.kanji) && hiragana_filtered_list.include?(w.kanji) )
          line = "#{w.kanji}\t#{w.meanings.first.content}"
        else
          kana = w.kana.present? ? "(#{w.kana})" : ""
          meanings = w.meanings.map(&:content).join("; ")
          # w.meanings.each do |m|
          #   m
          # end
          line = "#{w.kanji} #{kana}\t#{meanings}"
        end
          
        f.puts line
      end
    end
  end
  # x = eval(JlptWord.offset(rand(JlptWord.count)).limit(1).first.raw)
  def create_meaning
    # binding.pry
    hiragana_filtered_list = ["する", "から", "こと", "よる", "など", "この", "その", "まで", "もの", "これ", "よう", "より", "おく", "でも", "それ", "しかし", "つく", "のみ", "なお", "および", "だけ", "そして", "ながら", "それぞれ", "うち", "かつて", "ここ", "そこ", "ところ", "または", "ほぼ", "あるいは", "しか", "いずれ", "まま", "このよう", "そのまま", "つつ", "すぐ", "やる", "もう", "いわゆる", "しばしば", "まだ", "また", "なる", "きっかけ", "どう", "かなり", "すなわち", "だろう", "なら", "べき", "わけ", "かつ", "やや", "どちら", "やがて", "ちなみに", "らしい", "くらい", "ばかり", "もしくは", "しかしながら", "こちら", "もたらす", "そう", "むら", "こう", "こそ", "どの", "よす", "どこ", "つまり", "こうして", "ところが", "さえ", "そんな", "あらゆる", "かも", "ようやく", "やはり", "あなた", "ないし", "どのよう", "すら", "こなす", "たばこ", "もし", "かい", "しかも", "もちろん", "なり", "やってくる", "もっと", "さくら", "あくまで", "すずき", "とても", "どれ", "あの", "みどり", "とりわけ", "いまだ", "さようなら", "ならびに", "それほど", "なかなか", "たけし", "ずれる", "ずっと", "そもそも", "つぐ", "ため", "もはや", "じゃ", "したためる", "せい", "よって", "くぐる", "ない", "どのように", "どんな", "いけない", "りす", "いう", "いまだに", "たび", "いつ", "すると", "いかなる", "おおよそ", "あくまでも", "ひどい", "もっとも", "けど", "ひれ", "あまり", "いきなり", "とる", "ゆっくり", "たとえ", "おはよう", "うどん", "さほど", "きりん", "まるで"]
    later_ids = []
    Word.all.each do |w|
      raw = eval(w.raw)
      puts "#{w.id} #{w.kanji}"
      if !raw["found"].nil?
        if (is_hiragana(w.kanji) && hiragana_filtered_list.include?(w.kanji) ) || is_katakana(w.kanji)
          data = raw["data"].select{|r| r["word"] == w.kanji}
          data.each do |r|
            means = r["means"]
            means.each do |m|
              mean = Meaning.create!(content: m["mean"], word_id: w.id)
              examples = m["examples"]
              examples.each do |ex|
                Example.create!(content: ex["content"], mean: ex["mean"], transcription: ex["transcription"], meaning_id: mean.id)
              end
            end
          end
        end

        if is_kanji(w.kanji) #kanji
          relates = raw["data"].select{|r| r["word"] == w.kanji && r["phonetic"].present? }
          kanas = relates.map{|r| r["phonetic"].scan( /\p{Hiragana}+/ ).first}
          w.kana = kanas.join(",")
          binding.pry if w.kana == ","
          w.save!

          relates.each do |r|
            means = r["means"]
            means.each do |m|
              mean = Meaning.create!(content: m["mean"], word_id: w.id)
              examples = m["examples"]
              examples.each do |ex|
                Example.create!(content: ex["content"], mean: ex["mean"], transcription: ex["transcription"], meaning_id: mean.id)
              end
            end
          end
        end
      else
        puts "Later"
        later_ids << w.id
      end
    end
    binding.pry
  end

  def create_jisho_meaning
    words = Word.all.select{|w| raw = eval(w.raw); raw["found"].nil?}
    File.open("filtered_data/consider/jisho", 'w') do |f2|
      words.each do |w|
        raw = eval(w.raw)
        data = raw["data"].first["senses"].first["english_definitions"]
        # data = raw["data"].first["japanese"]
        puts "#kanji #{w.kanji}, meaning #{data}"
        f2.puts "id #{w.id}. kanji #{w.kanji}, meaning #{data}"
      end
    end
  end

  def create_missing_meanings
    ids = Meaning.all.map(&:word_id).uniq.compact
    Word.where("id not in (?)", ids).each do |w| 
      raw = eval(w.raw)
      puts "#{w.id} #{w.kanji}"
      if raw["found"].nil?
        data = raw["data"]
        data.each do |d|
          jp = d["japanese"].first
          jp_word = jp["word"]
          jp_reading = jp["reading"]
          is_existed = Word.where("kanji = ?", jp_word).length > 0
          next if is_existed || jp_word.blank?
          new_w = Word.create!(kanji: jp_word, kana: jp_reading, is_jisho: true)
          means = d["senses"].first["english_definitions"]
          means.each do |m|
            Meaning.create!(content: m, word_id: new_w.id)
          end
          w.destroy
        end
      end
    end
  end

  def create_missing_words
    ids = Meaning.all.map(&:word_id).uniq.compact
    File.open("filtered_data/consider/jisho1", 'w') do |f2|
      ws  = Word.where("id not in (?)", ids).select{|w| 
        raw = eval(w.raw)
        puts "#{w.id} #{w.kanji}"
        if raw["found"].nil?
          puts "#{raw["data"].first}"
          data = raw["data"].first["senses"].first["english_definitions"]
          puts "#kanji #{w.kanji}, meaning #{data}"
          f2.puts "id #{w.id}. kanji #{w.kanji}, meaning #{data}"
        end
      }
    end
  end

  def filter_15000
    File.open("raw_data/common/15000", 'r') do |f1|
      File.open("filtered_data/common/15000", 'w') do |f2|
        count = 0
        while line = f1.gets
          word = line.gsub("\n",'')
          next if !is_japanese(word) && !is_katakana(word) && !is_katakana(word)
          f2.puts line
          count += 1
        end
      end  
    end  
  end
end
