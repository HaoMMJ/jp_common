class AddReadingToJlptWord < ActiveRecord::Migration[5.0]
  def change
    add_column :jlpt_words, :reading, :string
  end
end
