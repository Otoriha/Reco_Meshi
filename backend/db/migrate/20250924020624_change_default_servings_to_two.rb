class ChangeDefaultServingsToTwo < ActiveRecord::Migration[7.2]
  def up
    change_column_default :recipes, :servings, 2
  end

  def down
    change_column_default :recipes, :servings, 1
  end
end
