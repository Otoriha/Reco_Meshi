class DislikedIngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :ingredient_id, :reason, :created_at, :updated_at

  attribute :priority do |object|
    object.priority
  end

  attribute :priority_label do |object|
    object.priority_label
  end

  attribute :ingredient do |object|
    if object.ingredient
      IngredientSerializer.new(object.ingredient).serializable_hash[:data][:attributes]
    end
  end
end
