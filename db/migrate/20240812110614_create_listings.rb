# frozen_string_literal: true

class CreateListings < ActiveRecord::Migration[7.2]
  def change
    create_table(:listings) do |t|
      t.string(:source_identifier, index: { unique: true })
      t.string(:street_address, null: false)
      t.string(:suite_number)
      t.string(:city)
      t.string(:postal_code)
      t.string(:listing_description)
      t.string(:building_description)
      t.integer(:minimum_size, null: false)
      t.integer(:maximum_size, null: false)
      t.integer(:minimum_term, null: false)
      t.decimal(:base_rent_per_month, precision: 8, scale: 2, null: false)
      t.string(:status, null: false)
      t.decimal(:building_size, precision: 8, scale: 2)

      t.timestamps
    end
  end
end
