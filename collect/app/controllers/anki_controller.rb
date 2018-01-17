# -*- coding: utf-8 -*-
class AnkiController < ApplicationController
  def detail
    @vocabs = AnkiVocabulary.all
  end

  def update
    ActiveRecord::Base.transaction do
      search_word = params['word']
      srv = Service::Anki.new
      
      if srv.check_exist(search_word)
        render json: { "message" => "existed" }
      else
        if search_word.contains_kanji?
          word = srv.update_new_word(search_word)
          if word.blank?
            render json: { "message" => "not_found" } 
          else
            render json: { "message" => "updated", 'word' => word.as_json}
          end
        else
          words = srv.get_missing_words(search_word)
          render json: { "message" => "missing_words", 'words' => words.as_json}
        end
      end
    end
  end

  def update_anki_vocab
    srv = Service::Anki.new
    anki_vocabulary = srv.insert_new_vocabulary(params["vocab_id"])
    if anki_vocabulary.present?
      render json: { "result" => anki_vocabulary.as_json }
    else
      render json: { "error_msg" => "Fail to save vocab id #{params["vocab_id"]}" }
    end
  end
end