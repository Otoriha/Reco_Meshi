class ShoppingListItemSerializer
  include JSONAPI::Serializer

  attributes :id, :quantity, :unit, :is_checked, :checked_at, :created_at, :updated_at, :lock_version

  belongs_to :shopping_list
  belongs_to :ingredient

  attribute :display_quantity_with_unit do |object|
    object.display_quantity_with_unit
  end

  attribute :ingredient_name do |object|
    object.ingredient_name
  end

  attribute :ingredient_category do |object|
    object.ingredient_category
  end

  attribute :ingredient_emoji do |object|
    object.ingredient&.emoji
  end

  attribute :ingredient_display_name do |object|
    object.ingredient&.display_name_with_emoji
  end

  attribute :checked_recently do |object|
    object.checked_recently?
  end

  attribute :status_display do |object|
    object.is_checked? ? '購入済み' : '未購入'
  end
end