# -*- coding: utf-8 -*-
class DictionaryController < ApplicationController
  def create_list_form
    @dictionary = Dictionary.new
  end

  def create_list
    p  = params["dictionary"]
    dic = Dictionary.where(name: p["name"], level: p["level"].to_i).first
    dic = Dictionary.create!(name: p["name"], level: p["level"].to_i) if dic.blank?
    redirect_to dictionary_detail_path(dic.id)
  end

  def update_list_form
    @dic = Dictionary.find(params[:id])
  end

  def update_dic_info
    @dic = Dictionary.find(params[:id])
    dic_params = params["dictionary"]
    @dic.name = dic_params["name"]
    @dic.level = dic_params["level"]
    @dic.save!
    redirect_to dictionary_detail_path(@dic.id)
  end

  def update_list
    search_word = params['word']
    if search_word.contains_kanji?
      vocabs = Vocabulary.where('kanji = ?', search_word)
    else
      vocabs = Vocabulary.where('kana = ?', search_word)
    end
    vocab_ids  = DicVocab.where('dictionary_id = ? and vocabulary_id in (?)', params["id"], vocabs.map(&:id)).map(&:vocabulary_id)


    if vocab_ids.length > 0
      render json: { "existed" => true }
    else
      if vocabs.length > 0
        DicVocab.create!(dictionary_id: params["id"], vocabulary_id: vocabs.first.id) if vocabs.length == 1
        render json: { 'result' => vocabs.map{|v| word_json(v)}}
      else
        puts "Vocabulary missing"
        
        source = 'mazii'
        data = search_from_mazi(params['word'])
        if data.blank? || !data["found"]
          data = search_from_jisho(params['word'])
          source = 'jisho'
        end

        if data.blank? || data["data"].blank?
          data = search_from_google(params['word'])
          source = 'google'
        end

        if data.present?
          json = data.is_a?(String) ? eval(data) : data
          new_word = import_new_word(params["id"], params['word'], json, source)
          render json: { 'result' => [word_json(new_word)] }
        else
          # render json: { "not_found" => true }
          render json: { 'result' => [word_json(search_word)] }
        end
      end
    end
  end

  def update_dic_vocab
    success = DicVocab.create(dictionary_id: params["dic_id"], vocabulary_id: params["vocab_id"])
    if success
      render json: { "successfull" => "save successfully" }
    else
      render json: { "error_msg" => "Fail to save dic id #{params['dic_id']} , vocab id #{vocab_id}" }
    end
  end

  def import_new_word(dic_id, search_word, raw, source)
    vocab = create_vocabulary_from_raw(search_word, raw, source)
    DicVocab.create!(dictionary_id: dic_id, vocabulary_id: vocab.id) if vocab.present?
    vocab
  end

  def import_data_to_vocabs
    RawDictionary.all.map(&:word).each do |w|
      import_to_vocabularies(w)
    end
  end

  def fix_vocab_kana
    Vocabulary.all.each do |w|
      if w.kana.blank?
        File.open("filtered_data/not_found/not_found_kana", 'a') do |f|
          f.puts "#{w.id} #{w.kanji}"
        end
        next
      end
      kana =  w.kana.scan( /\p{Hiragana}+/ ).first
      if kana.present?
        w.kana = kana
        w.save!
      end
    end
  end

  def generate_quizlet
    @dic = Dictionary.find(params[:id])
    File.open("filtered_data/dictionary/shinkanzen", 'w') do |f|
      @dic.vocabularies.each do |v|
        if v.kanji.present?
          f.puts "#{v.kanji} (#{v.kana}),(#{v.cn_mean}) #{v.mean}"
        else
          f.puts "#{v.kana},#{v.mean}"
        end
      end
    end
  end
end
