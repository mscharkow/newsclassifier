class AddClassifierCounter < ActiveRecord::Migration
  def self.up
    add_column :classifiers, :classifications_count, :integer, :default => 0

    Classifier.reset_column_information
    Classifier.find(:all).each do |p|
      Classifier.update_counters p.id, :classifications_count => p.classifications.count
    end
  end

  def self.down
    remove_column :classifiers, :classifications_count
  end
end
