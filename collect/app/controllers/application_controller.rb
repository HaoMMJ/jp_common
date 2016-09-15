class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  require "addressable/uri"

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
    url = Addressable::URI.parse("http://jisho.org/api/v1/search/words?keyword=#{word}").normalize.to_str
    request_word(url)
  end

  def update_raw_dictionary(word, raw, source)
    RawDictionary.create!(word: word, raw: raw, source: source)
  end

  def extract_mazii_raw(search_word, json)
    kanji = 
    vocabulary_object(kanji, kana, cn_mean, mean)
  end

  def extract_jisho_raw(search_word,json)
    vocabulary_object(kanji, kana, cn_mean, mean)
  end

  def extract_google_raw(search_word, json)
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

  def create_vocabulary_from_raw(dic_id, search_word, raw, source)
    json = raw.is_a?(String) ? eval(raw) : raw
    case source
    when "mazii"
      word = extract_mazii_raw(search_word, json)
    when "jisho"
      word = extract_jisho_raw(search_word, json)
    when "google"
      word = extract_google_raw(search_word, json)
    end
    return nil if word.blank?
    level = JlptWord.where("word = ?", w["search_word"]).map(&:level).max || 1

    vocab = Vocabulary.new
    vocab.kanji       = word[:kanji]
    vocab.kana        = word[:kana]
    vocab.cn_mean     = word[:cn_mean]
    vocab.mean        = word[:mean]
    vocab.level       = level
    vocab.from_source = source
    vocab.save!
    vocab
  end
end
