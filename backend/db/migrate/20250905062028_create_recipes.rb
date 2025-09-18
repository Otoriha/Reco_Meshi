class CreateRecipes < ActiveRecord::Migration[7.2]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'
      t.string :title, null: false, comment: '料理名'
      t.integer :cooking_time, null: false, comment: '調理時間（分）'
      t.string :difficulty, comment: '難易度（easy/medium/hard）'
      t.integer :servings, default: 1, comment: 'サービング数'
      t.jsonb :steps, null: false, default: '[]', comment: '調理手順（JSON）'
      t.string :ai_provider, null: false, comment: 'AIプロバイダー（openai/gemini等）'
      t.jsonb :ai_response, comment: '生成元のAIレスポンス（JSON）'

      t.timestamps
    end

    add_index :recipes, [ :user_id, :created_at ], name: 'index_recipes_on_user_id_created_at'
  end
end
