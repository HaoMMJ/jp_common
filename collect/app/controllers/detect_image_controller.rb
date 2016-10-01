# -*- coding: utf-8 -*-
class DetectImageController < ApplicationController
  def test
  end

  def detect_text_image
    json_params = ActionController::Parameters.new(JSON.parse(params[:search_image]))
	  preview_picture_data = json_params[:image_data]

  	image_data = Base64.decode64(preview_picture_data['data:image/jpeg;base64,'.length..-1])
    file = Tempfile.new(['detect_img_', '.jpeg'])
    File.open(file, 'wb') { |f| f.write(image_data) }
    # system "cp #{file.path} ~/jp_common/collect/"
    system "tesseract #{file.path} out -l jpn"
    found_txt = []
    File.open("out.txt", 'r') do |f1|
      while line = f1.gets
        next if line.strip.blank?
        found_txt << line.strip
      end
    end

    words = []

    found_txt.each do |f|
      list = detect_japanese(f)
      list.each do |w|
        word      = w[0]
        # kana      = w[1]
        # word_type = w[2]
        jishokei  = w[3]
        found_word = search_vocabulary(jishokei)
        words << found_word_json(found_word, word)
      end 
    end
	  render json: { 
      word_list: words
    } 
  end
end