# -*- coding: utf-8 -*-
class LessionController < ApplicationController
  def create_form
  	@lession = Lession.new
  end

  def create
    p  = params["lession"]

    lession = Lession.new(lession_params)
    if lession.valid?
      lession.save!
      system "tesseract #{lession.content_image.path} out -l jpn"
      found_txt = []
      File.open("out.txt", 'r') do |f1|
        while line = f1.gets
          next if line.strip.blank?
          found_txt << line.strip
        end
      end

      lession.content = found_txt.join("\n")
      lession.save!

      return redirect_to update_lession_form_path(lession.id)
    else
      render action: :create_form
    end
  end

  def update_form
    @lession = Lession.find(params[:id])
  end

  def update
  end

  private
  def lession_params
    params.require(:lession).permit(:name, :level, :content_image)
  end
end