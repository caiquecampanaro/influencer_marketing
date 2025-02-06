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

ActiveRecord::Schema[8.0].define(version: 2025_02_06_194953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.decimal "budget"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "influencer_campaigns", force: :cascade do |t|
    t.bigint "influencer_id", null: false
    t.bigint "campaign_id", null: false
    t.jsonb "custom_metrics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_influencer_campaigns_on_campaign_id"
    t.index ["influencer_id"], name: "index_influencer_campaigns_on_influencer_id"
  end

  create_table "influencers", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.string "platform"
    t.integer "followers"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_influencers_on_username", unique: true
  end

  add_foreign_key "influencer_campaigns", "campaigns"
  add_foreign_key "influencer_campaigns", "influencers"
end
