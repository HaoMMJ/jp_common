class Service::Anki
  def initialize
    @collect = Service::Collect.new
  end

  def import
    # AnkiVocabulary.delete_all
    count = 0
    File.open("data/full.txt", "r") do |infile|
      while (line = infile.gets)
        word, used_meaning, reading = line.split("\t")
        next if AnkiVocabulary.where(word: word).present?
        count += 1
        sleep 5 if count % 50 == 0
        anki_vocabulary = AnkiVocabulary.new
        anki_vocabulary.word = word.strip.chomp
        anki_vocabulary.reading = reading.strip.chomp
        anki_vocabulary.used_meaning = used_meaning.strip.chomp

        search_word = anki_vocabulary.word.split("(").first
        search_word = anki_vocabulary.word.split(")").last if search_word.blank?
        search_word = search_word.split("/").first

        vocabs = []
        if search_word.contains_kanji?
          vocabs = Vocabulary.where('kanji = ?', search_word).where(from_source: ["mazii", "jisho"])
        else
          vocabs = Vocabulary.where('kana = ?', search_word).where(from_source: ["mazii", "jisho"])
        end

        kanji_meaning = nil
        jisho_meaning = nil
        mazii_meaning = nil
        if vocabs.present?
          kanji_meaning = vocabs.first.cn_mean
          jisho = vocabs.select{|v| v.from_source == "jisho"}.first
          jisho_meaning = jisho.try(:mean)
          mazii = vocabs.select{|v| v.from_source == "mazii"}.first
          mazii_meaning = mazii.try(:mean)
        end
        if anki_vocabulary.word.contains_kanji?
          if kanji_meaning.present?
            anki_vocabulary.kanji_meaning = kanji_meaning
          else
            anki_vocabulary.kanji_meaning = get_kanji_meaning(search_word)
          end
        end
        if jisho_meaning.present?
          anki_vocabulary.jisho_meaning = jisho_meaning
        else
          anki_vocabulary.jisho_meaning = get_jisho_meaning(search_word)
        end

        if mazii_meaning.present?
          anki_vocabulary.mazii_meaning = mazii_meaning
        else
          anki_vocabulary.mazii_meaning = get_mazii_meaning(search_word)
        end
        anki_vocabulary.save
      end
    end
  end

  def import_new_word(search_word, raw, source)
    return nil if source == "mazii" && (raw["found"] == false || raw["status"] != 200)
    return nil if source == "jisho" && raw["data"].blank?
    vocab = @collect.create_vocabulary_from_raw(search_word, raw, source)
    vocab
  end

  def get_kanji_meaning(word)
    data = @collect.search_from_jisho(word)
    source = 'jisho'
    if data.present?
      json = data.is_a?(String) ? eval(data) : data
      new_word = import_new_word(word, json, source)
      return new_word.try(:cn_mean)
    end
    return nil
  end

  def get_jisho_meaning(word)
    data = @collect.search_from_jisho(word)
    source = 'jisho'
    if data.present?
      json = data.is_a?(String) ? eval(data) : data
      new_word = import_new_word(word, json, source)
      return new_word.try(:mean)
    end
    return nil
  end

  def get_mazii_meaning(word)
    data = @collect.search_from_mazi(word)
    source = 'mazii'
    if data.present?
      json = data.is_a?(String) ? eval(data) : data
      new_word = import_new_word(word, json, source)
      return new_word.try(:mean)
    end
    return nil
  end

  def get_jisho_vocab(word)
    data = @collect.search_from_jisho(word)
    source = 'jisho'
    if data.present?
      json = data.is_a?(String) ? eval(data) : data
      new_word = import_new_word(word, json, source)
      return new_word
    end
    return nil
  end

  def get_mazii_vocab(word)
    data = @collect.search_from_mazi(word)
    source = 'mazii'
    if data.present?
      json = data.is_a?(String) ? eval(data) : data
      new_word = import_new_word(word, json, source)
      return new_word
    end
    return nil
  end

  def search_vocab_from_source(word, source)
    vocab = Vocabulary.where(kanji: word).where(from_source: source).first
    return vocab if vocab.present?
    case source
    when 'mazii'
      get_mazii_vocab(word)
    when 'jisho'
      get_jisho_vocab(word)
    end
  end

  def insert_new_vocabulary(vocab_id)
    anki_vocabulary = nil
    begin
      vocab = Vocabulary.find_by_id(vocab_id.to_i)
      return anki_vocabulary if vocab.nil?
      is_jisho = vocab.from_source == "jisho"
      vocab_1 = is_jisho ? search_vocab_from_source(vocab.kanji, "mazii") : search_vocab_from_source(vocab.kanji, "jisho")
      anki_vocabulary = AnkiVocabulary.new
      anki_vocabulary.word = vocab.kanji
      anki_vocabulary.reading = is_jisho ? vocab.try(:kana) : vocab_1.try(:kana)
      anki_vocabulary.kanji_meaning = vocab.try(:cn_mean)
      anki_vocabulary.jisho_meaning = is_jisho ? vocab.try(:mean) : vocab_1.try(:mean)
      anki_vocabulary.mazii_meaning = is_jisho ? vocab_1.try(:mean) : vocab.try(:mean)
      anki_vocabulary.save!
      return anki_vocabulary
    rescue => e
      puts e
      return anki_vocabulary
    end
  end

  def text_filter(word)
    search_word = word.split("(").first
    search_word = word.split(")").last if search_word.blank?
    search_word = search_word.split("/").first
    search_word
  end

  def check_exist(search_word)
    if search_word.contains_kanji?
      vocabs = AnkiVocabulary.where("word like  ?", "%#{search_word}%")
      return vocabs.select{|v| text_filter(v.word) == search_word}.length > 0
    else
      vocabs = Vocabulary.where(kana: search_word).where(from_source: "jisho")
      anki_vocabs = AnkiVocabulary.where(reading: search_word)

      if vocabs.first.try(:get_full_kana) == true
        return anki_vocabs.length == vocabs.length && anki_vocabs.length > 0 && vocabs.length > 0
      else
        exist = true
        raw = @collect.search_from_jisho(search_word)
        return false if raw["data"].blank?
        data = raw["data"]
        words = data.select{|w| w["japanese"].first["reading"] == search_word}
        vocabs.update_all(get_full_kana: true) if vocabs.present?
        words.each{|w|
          v = w["japanese"].first
          word = v["word"]
          reading = v["reading"]
          next if vocabs.select{|voc| voc.try(:kanji) == word}.length > 0
          jisho_meaning = w["senses"].first["english_definitions"].join(",")
          kanji_meaning = (word.contains_kanji?) ? @collect.get_kanji_mean(word) : nil
          level = JlptWord.where("word = ?", word).map(&:level).max || 1
          exist = false
          vocab = Vocabulary.where("kanji = ? and kana = ?", word, reading).where(from_source: "jisho").first
          vocab = Vocabulary.new if vocab.blank?
          vocab.kanji       = word
          vocab.kana        = reading
          vocab.cn_mean     = kanji_meaning
          vocab.mean        = jisho_meaning
          vocab.level       = level
          vocab.from_source = "jisho"
          vocab.get_full_kana = true
          vocab.save!
        }
        return exist
      end
    end
  end

  def update_new_word(search_word)
    anki_vocabulary = nil
    vocabs = Vocabulary.where('kanji = ?', search_word).where(from_source: ["mazii", "jisho"])
    return nil if vocabs.blank?
    jisho_vocab = vocabs.select{|v| v.from_source == "jisho"}.first
    jisho_vocab = get_jisho_vocab(search_word) if jisho_vocab.nil?
    mazii_vocab = vocabs.select{|v| v.from_source == "mazii"}.first
    mazii_vocab = get_mazii_vocab(search_word) if mazii_vocab.nil?
    kanji_meaning = @collect.get_kanji_mean(search_word)
    anki_vocabulary = AnkiVocabulary.new
    anki_vocabulary.word = search_word
    anki_vocabulary.reading = jisho_vocab.try(:kana)
    anki_vocabulary.kanji_meaning = kanji_meaning
    anki_vocabulary.jisho_meaning = jisho_vocab.try(:mean)
    anki_vocabulary.mazii_meaning = mazii_vocab.try(:mean)
    anki_vocabulary.save
    anki_vocabulary
  end

  def get_missing_words(search_word)
    anki_vocabs = AnkiVocabulary.where(reading: search_word)
    vocabs = Vocabulary.where(kana: search_word).where(from_source: "jisho")
    return [] if vocabs.blank?
    dups = vocabs.select{|v| anki_vocabs.select{|av| av.try(:word) == v.kanji}.length > 0 }
    missing_words = vocabs - dups
    missing_words
  end
end