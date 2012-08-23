class AddCategoryCounter < ActiveRecord::Migration
  def self.up
    add_column :categories, :classifications_count, :integer, :default => 0

    Category.reset_column_information
    Category.find(:all).each do |p|
      Category.update_counters p.id, :classifications_count => p.classifications.length
    end
  end

  def self.down
    remove_column :categories, :classifications_count
  end
end
