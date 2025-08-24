class IngredientSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :category, :unit, :emoji, :created_at, :updated_at
  
  attribute :display_name_with_emoji do |object|
    object.display_name_with_emoji
  end
end

