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

ActiveRecord::Schema[7.2].define(version: 2025_09_11_080314) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "fridge_images", force: :cascade do |t|
    t.bigint "user_id", comment: "撮影したユーザー"
    t.bigint "line_account_id", comment: "LineAccountとの紐付け（Web版の場合はnull）"
    t.jsonb "recognized_ingredients", default: "[]", null: false, comment: "AI認識結果（JSON）"
    t.jsonb "image_metadata", default: "{}", comment: "画像メタデータ（JSON）"
    t.string "status", default: "pending", null: false, comment: "pending/processing/completed/failed"
    t.text "error_message", comment: "エラー時のメッセージ"
    t.string "line_message_id", comment: "LINE画像メッセージID"
    t.datetime "captured_at", precision: nil, comment: "撮影日時"
    t.datetime "recognized_at", precision: nil, comment: "認識実行日時"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_account_id"], name: "index_fridge_images_on_line_account_id"
    t.index ["line_message_id"], name: "index_fridge_images_on_line_message_id", where: "(line_message_id IS NOT NULL)"
    t.index ["recognized_at"], name: "index_fridge_images_on_recognized_at"
    t.index ["status"], name: "index_fridge_images_on_status"
    t.index ["user_id", "created_at"], name: "index_fridge_images_on_user_and_created"
    t.index ["user_id"], name: "index_fridge_images_on_user_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false, comment: "食材名"
    t.string "category", null: false, comment: "カテゴリー（野菜、肉、魚など）"
    t.string "unit", null: false, comment: "単位（個、g、mlなど）"
    t.string "emoji", comment: "絵文字アイコン"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_ingredients_on_category"
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylists_on_exp"
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "line_accounts", force: :cascade do |t|
    t.string "line_user_id", null: false
    t.bigint "user_id"
    t.string "line_display_name"
    t.string "line_picture_url"
    t.datetime "linked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_user_id"], name: "index_line_accounts_on_line_user_id", unique: true
    t.index ["user_id"], name: "index_line_accounts_on_user_id"
  end

  create_table "recipe_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "cooked_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rating"
    t.index ["recipe_id"], name: "index_recipe_histories_on_recipe_id"
    t.index ["user_id", "cooked_at"], name: "index_recipe_histories_on_user_id_and_cooked_at"
    t.index ["user_id"], name: "index_recipe_histories_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "rating_between_1_and_5"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false, comment: "レシピID"
    t.bigint "ingredient_id", comment: "食材ID（マッチング成功時）"
    t.string "ingredient_name", comment: "食材名（マッチング失敗時のフォールバック）"
    t.decimal "amount", precision: 10, scale: 2, comment: "必要量"
    t.string "unit", limit: 20, comment: "単位（g、個、大さじ等）"
    t.boolean "is_optional", default: false, null: false, comment: "任意の食材フラグ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
    t.check_constraint "ingredient_id IS NOT NULL OR ingredient_name IS NOT NULL", name: "chk_ingredient_id_or_name_required"
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.string "title", null: false, comment: "料理名"
    t.integer "cooking_time", null: false, comment: "調理時間（分）"
    t.string "difficulty", comment: "難易度（easy/medium/hard）"
    t.integer "servings", default: 1, comment: "サービング数"
    t.jsonb "steps", default: "[]", null: false, comment: "調理手順（JSON）"
    t.string "ai_provider", null: false, comment: "AIプロバイダー（openai/gemini等）"
    t.jsonb "ai_response", comment: "生成元のAIレスポンス（JSON）"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_recipes_on_user_id_created_at"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.bigint "shopping_list_id", null: false, comment: "所属する買い物リスト"
    t.bigint "ingredient_id", null: false, comment: "購入する食材"
    t.decimal "quantity", precision: 10, scale: 2, null: false, comment: "購入量"
    t.string "unit", limit: 20, null: false, comment: "単位"
    t.boolean "is_checked", default: false, null: false, comment: "購入済みチェック"
    t.datetime "checked_at", comment: "チェック日時（監査用）"
    t.integer "lock_version", default: 0, null: false, comment: "楽観ロック用バージョン"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_shopping_list_items_on_ingredient_id"
    t.index ["is_checked"], name: "index_shopping_list_items_on_is_checked"
    t.index ["shopping_list_id", "ingredient_id"], name: "idx_on_shopping_list_id_ingredient_id_f6963fd74f", unique: true
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "リスト作成者"
    t.bigint "recipe_id", comment: "基となったレシピ"
    t.integer "status", default: 0, null: false, comment: "リストの状態（0:pending, 1:in_progress, 2:completed）"
    t.string "title", limit: 100, comment: "買い物リストタイトル"
    t.text "note", comment: "メモ欄"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_shopping_lists_on_recipe_id"
    t.index ["status"], name: "index_shopping_lists_on_status"
    t.index ["user_id", "created_at"], name: "index_shopping_lists_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_shopping_lists_on_user_id"
  end

  create_table "user_ingredients", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.bigint "ingredient_id", null: false, comment: "食材ID"
    t.decimal "quantity", precision: 10, scale: 2, null: false, comment: "数量"
    t.date "expiry_date", comment: "賞味期限"
    t.string "status", default: "available", null: false, comment: "available/used/expired"
    t.bigint "fridge_image_id", comment: "認識元の画像"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expiry_date"], name: "index_user_ingredients_on_expiry_date"
    t.index ["fridge_image_id"], name: "index_user_ingredients_on_fridge_image_id"
    t.index ["ingredient_id"], name: "index_user_ingredients_on_ingredient_id"
    t.index ["status"], name: "index_user_ingredients_on_status"
    t.index ["user_id", "ingredient_id", "status"], name: "idx_user_ingredients_composite"
    t.index ["user_id", "status", "expiry_date"], name: "idx_user_ingredients_user_status_expiry"
    t.index ["user_id"], name: "index_user_ingredients_on_user_id"
    t.check_constraint "quantity >= 0::numeric", name: "chk_quantity_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider", default: "email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "fridge_images", "line_accounts"
  add_foreign_key "fridge_images", "users"
  add_foreign_key "line_accounts", "users", on_delete: :nullify
  add_foreign_key "recipe_histories", "recipes"
  add_foreign_key "recipe_histories", "users"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes", on_delete: :cascade
  add_foreign_key "recipes", "users"
  add_foreign_key "shopping_list_items", "ingredients"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_lists", "recipes"
  add_foreign_key "shopping_lists", "users"
  add_foreign_key "user_ingredients", "fridge_images"
  add_foreign_key "user_ingredients", "ingredients"
  add_foreign_key "user_ingredients", "users"
end
