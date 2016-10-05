class Lession < ApplicationRecord
  has_attached_file :content_image, :styles => { :thumb => "150x150>" },
                    :url  => "/assets/lessions/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/lessions/:id/:style/:basename.:extension"


  validates_attachment_presence :content_image
  # validates_attachment_size :content_image, :less_than => 5.megabytes
  validates_attachment_content_type :content_image, :content_type => ['image/jpeg', 'image/png']
end