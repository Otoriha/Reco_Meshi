class RecipeIngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :amount, :unit, :is_optional, :created_at, :updated_at

  belongs_to :recipe
  belongs_to :ingredient
end


