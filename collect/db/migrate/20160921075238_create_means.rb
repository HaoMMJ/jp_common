class CreateMeans < ActiveRecord::Migration[5.0]
  def change
    create_table :means do |t|
      t.references :vocabulary
      t.text       :content
    end
  end
end
