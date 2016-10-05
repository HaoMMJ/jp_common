class CreateLession < ActiveRecord::Migration[5.0]
  def change
    create_table :lessions do |t|
      t.string :name
      t.text   :content
      t.integer :level
    end
  end
end
