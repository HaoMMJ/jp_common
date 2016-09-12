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

  def update_list
  end
end
