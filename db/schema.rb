# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_08_12_110614) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "listings", force: :cascade do |t|
    t.string "source_identifier"
    t.string "street_address", null: false
    t.string "suite_number"
    t.string "city"
    t.string "postal_code"
    t.string "listing_description"
    t.string "building_description"
    t.integer "minimum_size", null: false
    t.integer "maximum_size", null: false
    t.integer "minimum_term", null: false
    t.decimal "base_rent_per_month", precision: 8, scale: 2, null: false
    t.string "status", null: false
    t.decimal "building_size", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_identifier"], name: "index_listings_on_source_identifier", unique: true
  end
end
