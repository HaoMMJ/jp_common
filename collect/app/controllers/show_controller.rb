# -*- coding: utf-8 -*-
class ShowController < ApplicationController
  def common_list
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

  def is_hiragana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def is_katakana(w)
    !!(w =~ /\p{Katakana}+/)
  end

  def is_kanji(w)
    !is_katakana(w) && !is_hiragana(w)
  end
end