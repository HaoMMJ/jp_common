class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  require "addressable/uri"
  require "romaji"
  require 'mecab'

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
    !!(w =~ /^([\p{Hiragana}\p{Katakana}\p{Han}ー]*)$/)
  end

  def contains_japanese(w)
    !!(w =~ /([\p{Hiragana}\p{Katakana}\p{Han}ー]+)/)
  end

  def search_from_raw_dictionary(word)
    raw = RawDictionary.where("word = ?", word).first
    raw.try(:raw)
  end

  def request_word(url)
    res = RestClient.get(url)
    return ActiveSupport::JSON.decode(res) if res.code == 200
    nil
  end

  def search_from_mazi(word)
    url = Addressable::URI.parse("http://mazii.net/api/search/#{word}/10/1").normalize.to_str
    request_word(url)
  end

  def search_from_jisho(word)
    url = Addressable::URI.parse("http://jisho.org/api/v1/search/words?keyword=#{word}").normalize.to_str
    request_word(url)
  end

  # http://mazii.net/api/gsearch/%E8%AA%AD%E8%A7%A3/ja/vi
  def search_from_google(word)
    url = Addressable::URI.parse("http://mazii.net/api/gsearch/#{word}/ja/vi").normalize.to_str
    request_word(url)
  end

  def update_raw_dictionary(word, raw, source)
    dic = RawDictionary.where("word = ?", word)
    dic = RawDictionary.new(word: word) if dic.blank?
    dic.raw = raw
    dic.source = source
    dic.save!
  end

  def get_kanji_mean(kanji)
    a = kanji.split("")
    means = []
    a.each do |c|
      km = KanjiDictionary.where("kanji = ?", c).first.try(:kanji_mean)
      next if km.blank?
      kms = km.split(",")
      m = kms.length > 1 ? "#{kms[0]}(#{kms[1]})" : km
      means << m.capitalize
    end
    kanji_mean = means.length > 0 ? means.join(" ") : means[0]
    kanji_mean
  end

  def extract_mazii_json(search_word, json)
    data = json["data"]

    if is_kanji(search_word)
      word = data.select{|w| w["word"] == search_word}.first
      kanji = search_word
      kana = word["phonetic"]
    else
      word = data.select{|w| w["phonetic"] == search_word}.first
      kana = search_word
      kanji = word["word"]
    end
    cn_mean = kanji.present? ? get_kanji_mean(kanji) : ""
    mean = word["means"].map{|w| w["mean"]}.join(",")
    vocabulary_object(kanji, kana, cn_mean, mean)
  end

  def extract_jisho_json(search_word,json)
    data = json['data'].first
    if is_kanji(search_word)
      kanji = search_word
      jp = data["japanese"].select{|w| w['word'] == kanji || (w['word'].present? && w['word'].include?(kanji))}.first
      kana = jp.present? ? jp["reading"] : ""
    else
      kana = search_word
      jp = data["japanese"].select{|w| w['reading'] == kana || (w['reading'].present? && w['reading'].include?(kana))}.first
      kanji = jp.present? ? jp["word"] : ""
    end
    cn_mean = kanji.present? ? get_kanji_mean(kanji) : ""
    mean = data["senses"].first["english_definitions"].join(",")
    vocabulary_object(kanji, kana, cn_mean, mean)
  end

  def extract_google_json(search_word, json)
    data = eval(json["data"])
    if is_kanji(search_word)
      kanji = search_word
      kana  = ""
    else
      kanji = ""
      kana = search_word
    end
    cn_mean = kanji.present? ? get_kanji_mean(kanji) : ""
    mean = data[:sentences].first[:trans]
    vocabulary_object(kanji, kana, cn_mean, mean)
  end

  def vocabulary_object(kanji, kana, cn_mean, mean)
    {
      kanji: kanji,
      kana: kana,
      cn_mean: cn_mean,
      mean: mean
    }
  end

  def create_vocabulary_from_raw(search_word, raw, source)
    return nil unless is_japanese(search_word)
    json = raw.is_a?(String) ? eval(raw) : raw
    case source
    when "mazii"
      word = extract_mazii_json(search_word, json)
    when "jisho"
      word = extract_jisho_json(search_word, json)
    when "google"
      word = extract_google_json(search_word, json)
    end
    return nil if word.blank?
    level = JlptWord.where("word = ?", search_word).map(&:level).max || 1


    vocab = Vocabulary.where("kanji = ? and kana = ?", word[:kanji], word[:kana]).first
    vocab = Vocabulary.new if vocab.blank?
    vocab.kanji       = word[:kanji]
    vocab.kana        = word[:kana]
    vocab.cn_mean     = word[:cn_mean]
    vocab.mean        = word[:mean]
    vocab.level       = level
    vocab.from_source = source
    vocab.save!
    vocab
  end

  def romaji_to_kana(str)
    Romaji.romaji2kana(str, :kana_type => :hiragana)
  end

  def import_to_vocabularies(word)
    vocabs = Vocabulary.where('kanji = ? or kana = ?', word, word)
    if vocabs.length == 0
      data = search_from_raw_dictionary(word)
      missing_in_raw_dictionary = data.blank?
      source = 'mazii'
      data = search_from_mazi(word) if data.blank?
      data = data.is_a?(String) ? eval(data) : data
      if data.blank? || !data["found"]
        data = search_from_jisho(word)
        source = 'jisho'
      end

      if data.blank? || data["data"].blank?
        data = search_from_google(word)
        source = 'google'
      end

      if data.present?
        json = data.is_a?(String) ? eval(data) : data
        update_raw_dictionary(word, data, source) if missing_in_raw_dictionary
        create_vocabulary_from_raw(word, json, source)
      else
        File.open("filtered_data/not_found/import_to_vocabularies", 'a') do |f|
          f.puts word
        end
      end
    end
  end

  def detect_japanese(search_text)
    tagger = MeCab::Tagger.new
    text = tagger.parse(search_text)
    lines = text.split("\n")
    found_words = []
    lines.each do |w|
      next if w == "EOS"
      line = w.split("\t")
      word = line[0]
      next if !is_japanese(word) || (is_hiragana(word) && word.length < 3)
      content = line[1].split(",")
      word_type = content.first
      reading = content.last.hiragana
      jishokei = content[-3]
      found_words << [word, reading, word_type, jishokei]
    end
    found_words.compact.uniq
  end

  def search_vocabulary(word)
    if is_kanji(word)
      Vocabulary.where("kanji = ?", "#{word}").first
    else
      Vocabulary.where("kana = ? and (kanji is null or kanji = '')", "#{word}").first
      vocab = Vocabulary.where("kana = ? and (kanji is null or kanji = '')", "#{word}").first
      vocab = Vocabulary.where(kana: word).first if vocab.blank?
      vocab
    end
  end

  def is_upper(word)
    !!/[[:upper:]]/.match(word)
  end

  def is_lower(word)
    !!/[[:lower:]]/.match(word)
  end
end
