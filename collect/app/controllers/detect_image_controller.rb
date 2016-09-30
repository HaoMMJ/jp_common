# -*- coding: utf-8 -*-
class DetectImageController < ApplicationController
  def test
  end

  def detect_text_image
	preview_picture_data = params["search_image"]
  	image_data = Base64.decode64(preview_picture_data['data:image/png;base64,'.length..-1])
    file = Tempfile.new(['detect_img_', '.png'])
    File.open(file, 'wb') { |f| f.write(image_data) }
    binding.pry
	render json: { 
      translated_txt: found_txt
    }
  end 
end