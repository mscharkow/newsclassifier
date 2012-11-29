# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121122195439) do

  create_table "bodies", :force => true do |t|
    t.integer  "document_id"
    t.text     "content"
    t.text     "raw_content"
    t.text     "summary"
    t.text     "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bodies", ["document_id"], :name => "index_bodies_on_document_id"

  create_table "categories", :force => true do |t|
    t.integer  "classifier_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "value"
    t.integer  "position"
    t.integer  "classifications_count", :default => 0
  end

  create_table "classifications", :force => true do |t|
    t.integer  "document_id"
    t.integer  "category_id"
    t.integer  "user_id"
    t.float    "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifier_id"
  end

  add_index "classifications", ["category_id"], :name => "index_classifications_on_category_id"
  add_index "classifications", ["classifier_id"], :name => "index_classifications_on_classifier_id"
  add_index "classifications", ["document_id"], :name => "index_classifications_on_document_id"

  create_table "classifiers", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "categories_count",      :default => 0
    t.text     "regexp"
    t.string   "type"
    t.text     "parts"
    t.text     "reliability"
    t.integer  "classifications_count", :default => 0
    t.integer  "teacher_id"
  end

  create_table "classifiers_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "classifier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.integer  "source_id"
    t.datetime "pubdate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.integer  "position"
    t.string   "url"
    t.integer  "classifications_count", :default => 0
  end

  add_index "documents", ["pubdate", "source_id"], :name => "index_documents_on_pubdate_and_source_id"
  add_index "documents", ["source_id", "pubdate"], :name => "index_documents_on_source_id_and_pubdate"
  add_index "documents", ["source_id"], :name => "index_documents_on_source_id"
  add_index "documents", ["url"], :name => "index_documents_on_url"

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "permalink"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "metadata"
    t.text     "announcements"
  end

  create_table "samples", :force => true do |t|
    t.integer  "project_id"
    t.text     "items"
    t.text     "metadata"
    t.boolean  "active"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sources", :force => true do |t|
    t.string   "name"
    t.text     "urls"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "documents_count", :default => 0
    t.boolean  "auto_update"
    t.text     "metadata"
    t.integer  "project_id"
  end

  add_index "sources", ["auto_update"], :name => "index_sources_on_auto_update"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password",        :limit => 128, :default => "", :null => false
    t.string   "password_salt",                            :default => "", :null => false
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.boolean  "admin"
    t.string   "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.datetime "remember_created_at"
  end

end
