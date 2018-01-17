class AddAttachmentContentImageToLessions < ActiveRecord::Migration
  def self.up
    change_table :lessions do |t|
      t.attachment :content_image
    end
  end

  def self.down
    remove_attachment :lessions, :content_image
  end
end
