# -*- coding: utf-8 -*-
class DictionaryController < ApplicationController
  def create_list_form
    @dictionary = Dictionary.new
  end

  def create_list
    p  = params["dictionary"]
    dic = Dictionary.first_or_create(name: p["name"], level: p["level"].to_i)
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
    binding.pry
    vocab_ids  = DicVocab.where(dictionary_id: params["id"]).map(&:vocabulary_id)
    vocabs     = Vocabulary.where('id in (?) and (kanji = ? or kana = ?)', vocab_ids, params['word'], params['word'])
    if vocabs.length > 0
      render json: { "existed" => true }
    else
      data = search_from_raw_dictionary(params['word'])
      missing_in_raw_dictionary = data.blank?
      source = 'mazii'
      data = search_from_mazi(params['word']) if data.blank?
      if data.blank?
        data = search_from_jisho(params['word'])
        source = 'jisho'
      end

      if data.blank?
        data = search_from_google(params['word'])
        source = 'google'
      end

      if data.present?
        update_raw_dictionary(params['word'], data, source) if missing_in_raw_dictionary
        new_word = import_new_word(params["id"], params['word'], data, source)
        render json: { 'result' => {
            kanji:   data.kanji,
            kana:    data.kana,
            cn_mean: data.cn_mean,
            mean:    data.mean,
            level:   data.level
          } 
        }
      else
        render json: { "not_found" => true }
      end
    end
  end

  def import_new_word(dic_id, search_word, raw, source)
    vocab = create_vocabulary_from_raw(dic_id, search_word, raw, source)
    binding.pry if vocab.blank?
    DicVocab.create!(dictionary_id: dic_id, vocabulary_id: vocab.id)
  end
end
