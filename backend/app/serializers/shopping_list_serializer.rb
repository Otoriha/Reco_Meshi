class ShoppingListSerializer
  include JSONAPI::Serializer

  attributes :id, :status, :title, :note, :created_at, :updated_at

  belongs_to :user
  belongs_to :recipe
  has_many :shopping_list_items

  attribute :display_title do |object|
    object.display_title
  end

  attribute :completion_percentage do |object|
    object.completion_percentage
  end

  attribute :total_items_count do |object|
    object.total_items_count
  end

  attribute :unchecked_items_count do |object|
    object.unchecked_items_count
  end

  attribute :can_be_completed do |object|
    object.can_be_completed?
  end

  attribute :status_display do |object|
    case object.status
    when "pending"
      "作成済み"
    when "in_progress"
      "買い物中"
    when "completed"
      "完了"
    else
      object.status
    end
  end
end
