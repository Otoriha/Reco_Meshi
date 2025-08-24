class UserIngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :ingredient_id, :quantity, :status, :expiry_date, :created_at, :updated_at

  attribute :ingredient do |object|
    IngredientSerializer.new(object.ingredient).serializable_hash[:data][:attributes] if object.ingredient
  end

  attribute :display_name do |object|
    object.display_name
  end

  attribute :formatted_quantity do |object|
    object.formatted_quantity
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

