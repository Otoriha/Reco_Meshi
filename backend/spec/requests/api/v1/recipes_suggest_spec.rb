require 'rails_helper'

RSpec.describe "POST /api/v1/recipes/suggest", type: :request do
  let(:user) { create(:user, :confirmed) }

  def auth_header_for(user)
    post "/api/v1/auth/login", params: { user: { email: user.email, password: 'password123' } }, as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe "POST /api/v1/recipes/suggest" do
    context "認証済みユーザーの場合" do
      context "食材を指定してレシピ提案する場合" do
        let(:request_params) do
          {
            recipe_suggestion: {
              ingredients: [ "玉ねぎ", "豚肉", "人参" ],
              preferences: {
                cooking_time: 30,
                difficulty_level: "easy",
                cuisine_type: "和食",
                dietary_restrictions: [ "ベジタリアン" ]
              }
            }
          }
        end

        it "指定食材からレシピを生成して返す" do
          # RecipeGeneratorをモック化
          recipe = create(:recipe, user: user, title: "豚肉と野菜の炒め物")
          generator = instance_double(RecipeGenerator)
          allow(RecipeGenerator).to receive(:new).with(user: user).and_return(generator)
          allow(generator).to receive(:generate_from_ingredients)
            .with([ "玉ねぎ", "豚肉", "人参" ], {
              "cooking_time" => "30",
              "difficulty_level" => "easy",
              "cuisine_type" => "和食",
              "dietary_restrictions" => [ "ベジタリアン" ]
            })
            .and_return(recipe)

          post "/api/v1/recipes/suggest", params: request_params, headers: auth_header_for(user)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["success"]).to be true
          expect(response.parsed_body["data"]["id"]).to eq recipe.id
          expect(response.parsed_body["data"]["title"]).to eq "豚肉と野菜の炒め物"
        end
      end

      context "食材を指定せずにレシピ提案する場合" do
        let(:request_params) do
          {
            recipe_suggestion: {
              preferences: {
                cooking_time: 20,
                difficulty_level: "medium"
              }
            }
          }
        end

        before do
          # ユーザーの在庫食材を作成
          ingredient1 = create(:ingredient, name: "鶏肉", unit: "g")
          ingredient2 = create(:ingredient, name: "キャベツ", unit: "個")
          create(:user_ingredient, user: user, ingredient: ingredient1, quantity: 300)
          create(:user_ingredient, user: user, ingredient: ingredient2, quantity: 1)
        end

        it "ユーザーの在庫食材からレシピを生成して返す" do
          recipe = create(:recipe, user: user, title: "鶏肉とキャベツの炒め物")
          generator = instance_double(RecipeGenerator)
          allow(RecipeGenerator).to receive(:new).with(user: user).and_return(generator)
          allow(generator).to receive(:generate_from_user_ingredients)
            .with({
              "cooking_time" => "20",
              "difficulty_level" => "medium"
            })
            .and_return(recipe)

          post "/api/v1/recipes/suggest", params: request_params, headers: auth_header_for(user)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["success"]).to be true
          expect(response.parsed_body["data"]["id"]).to eq recipe.id
          expect(response.parsed_body["data"]["title"]).to eq "鶏肉とキャベツの炒め物"
        end
      end

      context "パラメータなしでレシピ提案する場合" do
        it "ユーザーの在庫食材からレシピを生成して返す" do
          recipe = create(:recipe, user: user, title: "簡単レシピ")
          generator = instance_double(RecipeGenerator)
          allow(RecipeGenerator).to receive(:new).with(user: user).and_return(generator)
          allow(generator).to receive(:generate_from_user_ingredients).with({}).and_return(recipe)

          post "/api/v1/recipes/suggest", headers: auth_header_for(user)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["success"]).to be true
          expect(response.parsed_body["data"]["id"]).to eq recipe.id
        end
      end

      context "バリデーションエラーの場合" do
        it "食材が配列でない場合は400エラーを返す" do
          request_params = {
            recipe_suggestion: {
              ingredients: "玉ねぎ"  # 配列ではない
            }
          }

          post "/api/v1/recipes/suggest", params: request_params, headers: auth_header_for(user)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to be false
          expect(response.parsed_body["message"]).to eq "食材は配列で指定してください"
          expect(response.parsed_body["errors"]).to include("ingredients must be an array")
        end
      end

      context "レシピ生成エラーの場合" do
        it "RecipeGenerator::GenerationErrorが発生した場合は422エラーを返す" do
          generator = instance_double(RecipeGenerator)
          allow(RecipeGenerator).to receive(:new).with(user: user).and_return(generator)
          allow(generator).to receive(:generate_from_user_ingredients)
            .with({})
            .and_raise(RecipeGenerator::GenerationError, "利用可能な食材が見つかりません")

          post "/api/v1/recipes/suggest", headers: auth_header_for(user)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["success"]).to be false
          expect(response.parsed_body["message"]).to eq "レシピ生成に失敗しました"
          expect(response.parsed_body["errors"]).to include("利用可能な食材が見つかりません")
        end
      end

      context "想定外のエラーの場合" do
        it "500エラーを返す" do
          generator = instance_double(RecipeGenerator)
          allow(RecipeGenerator).to receive(:new).with(user: user).and_return(generator)
          allow(generator).to receive(:generate_from_user_ingredients)
            .with({})
            .and_raise(StandardError, "予期しないエラー")

          post "/api/v1/recipes/suggest", headers: auth_header_for(user)

          expect(response).to have_http_status(:internal_server_error)
          expect(response.parsed_body["success"]).to be false
          expect(response.parsed_body["message"]).to eq "内部エラーが発生しました。しばらくしてから再度お試しください。"
        end
      end
    end

    context "未認証ユーザーの場合" do
      it "401エラーを返す" do
        post "/api/v1/recipes/suggest"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
