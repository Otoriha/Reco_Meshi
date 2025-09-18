class UserIngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :ingredient_id, :status, :expiry_date, :created_at, :updated_at

  attribute :quantity do |object|
    object.quantity.to_f
  end

  attribute :ingredient do |object|
    if object.ingredient
      IngredientSerializer.new(object.ingredient).serializable_hash[:data][:attributes]
    else
      nil
    end
  end

  attribute :display_name do |object|
    object.ingredient ? object.display_name : "Unknown Ingredient"
  end

  attribute :formatted_quantity do |object|
    object.ingredient ? object.formatted_quantity : "#{object.quantity || 0}"
  end

  attribute :days_until_expiry do |object|
    object.days_until_expiry
  end

  attribute :expired do |object|
    object.expired?
  end

  attribute :expiring_soon do |object|
    object.expiring_soon?
  end
end
