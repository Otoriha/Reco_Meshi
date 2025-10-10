class AllergyIngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :ingredient_id, :note, :created_at, :updated_at

  attribute :ingredient do |object|
    if object.ingredient
      IngredientSerializer.new(object.ingredient).serializable_hash[:data][:attributes]
    else
      nil
    end
  end
end
