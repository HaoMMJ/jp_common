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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160914173549) do

  create_table "dic_vocabs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "dictionary_id"
    t.integer "vocabulary_id"
    t.index ["dictionary_id"], name: "index_dic_vocabs_on_dictionary_id", using: :btree
    t.index ["vocabulary_id"], name: "index_dic_vocabs_on_vocabulary_id", using: :btree
  end

  create_table "dictionaries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "name"
    t.integer "level"
  end

  create_table "examples", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "meaning_id"
    t.text    "content",       limit: 65535
    t.text    "mean",          limit: 65535
    t.text    "transcription", limit: 65535
    t.index ["meaning_id"], name: "index_examples_on_meaning_id", using: :btree
  end

  create_table "jlpt_kanjis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "kanji"
    t.text    "raw",   limit: 65535
    t.integer "level"
  end

  create_table "jlpt_words", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "word"
    t.text    "raw",   limit: 65535
    t.integer "level"
  end

  create_table "kanji_samples", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "jlpt_kanji_id"
    t.string  "word"
    t.string  "kana"
    t.string  "am_han"
    t.text    "meaning",       limit: 65535
    t.index ["jlpt_kanji_id"], name: "index_kanji_samples_on_jlpt_kanji_id", using: :btree
  end

  create_table "meanings", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text    "content", limit: 65535
    t.integer "word_id"
  end

  create_table "raw_dictionaries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "word"
    t.text   "raw",    limit: 65535
    t.string "source",               default: "mazii"
  end

  create_table "vocabularies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "kanji"
    t.string  "kana"
    t.text    "raw",         limit: 65535
    t.text    "cn_mean",     limit: 65535
    t.text    "mean",        limit: 65535
    t.integer "level"
    t.string  "from_source",               default: "mazii"
  end

  create_table "words", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "kanji"
    t.string  "kana"
    t.text    "raw",      limit: 65535
    t.boolean "is_jisho"
  end

end
