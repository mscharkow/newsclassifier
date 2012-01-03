class InitialMigration < ActiveRecord::Migration
  def self.up
    create_table "bodies", :force => true do |t|
      t.integer  "document_id"
      t.text     "content"
      t.text     "raw_content"
      t.text     "summary"
      t.text     "metadata"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "categories", :force => true do |t|
      t.integer  "classifier_id"
      t.string   "name"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "value"
      t.integer  "position"
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

    create_table "classifiers", :force => true do |t|
      t.string   "name"
      t.integer  "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "description"
      t.integer  "categories_count", :default => 0
      t.text     "regexp"
      t.string   "type"
      t.text     "parts"
      t.text     "reliability"
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
      t.integer  "documents_count",   :default => 0
      t.boolean  "auto_update"
      t.text     "metadata"
      t.integer  "project_id"
    end

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

  def self.down
  end
end
