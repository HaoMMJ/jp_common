# -*- coding: utf-8 -*-
class ShowController < ApplicationController
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

  def is_hiragana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def is_katakana(w)
    !!(w =~ /\p{Katakana}+/)
  end

  def is_kanji(w)
    !is_katakana(w) && !is_hiragana(w)
  end

  def is_japanese(w)
    !!(w =~ /^([\p{Hiragana}\p{Katakana}\p{Han}]*)$/)
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