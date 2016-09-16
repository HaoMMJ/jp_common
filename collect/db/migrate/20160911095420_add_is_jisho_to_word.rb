class AddIsJishoToWord < ActiveRecord::Migration[5.0]
  def change
    add_column :words, :is_jisho, :boolean
  end
end
