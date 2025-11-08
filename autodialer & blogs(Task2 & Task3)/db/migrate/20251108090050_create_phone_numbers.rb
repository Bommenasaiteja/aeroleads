class CreatePhoneNumbers < ActiveRecord::Migration[7.1]
  def change
    create_table :phone_numbers do |t|
      t.string :number
      t.string :name
      t.string :status
      t.datetime :uploaded_at

      t.timestamps
    end
  end
end
