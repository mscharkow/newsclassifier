class ChangeScoreColumn < ActiveRecord::Migration
  def up
    change_column :classifications, :score, :text
  end

  def down
    change_column :classifications, :score, :float
  end
end
