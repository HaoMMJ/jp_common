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
  end
 
  def update_list
    vocab_ids  = DicVocab.where(dictionary_id: params["id"]).map(&:vocabulary_id)
    vocabs     = Vocabulary.where('id in (?) and (kanji = ? or kana = ?)', vocab_ids, params['word'], params['word'])
    if vocabs.length > 0
      render json: { "existed" => true }
    else
      data = search_from_raw_dictionary(params['word'])
      missing_in_raw_dictionary = data.blank?
      source = 'mazii'
      data = search_from_mazi(params['word']) if data.blank?
      if data.blank? || !eval(data)["found"]
        data = search_from_jisho(params['word'])
        source = 'jisho'
      end

      if data.blank? || data["data"].blank?
        data = search_from_google(params['word'])
        source = 'google'
      end

      if data.present?
        json = data.is_a?(String) ? eval(data) : data
        update_raw_dictionary(params['word'], data, source) if missing_in_raw_dictionary
        new_word = import_new_word(params["id"], params['word'], json, source)
        render json: { "not_found" => true } if new_word.blank?
        render json: { 'result' => {
            kanji:   new_word.kanji.to_s,
            kana:    new_word.kana.to_s,
            cn_mean: new_word.cn_mean.to_s,
            mean:    new_word.mean.to_s,
            level:   new_word.level.to_s
          } 
        }
      else
        render json: { "not_found" => true }
      end
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
end
