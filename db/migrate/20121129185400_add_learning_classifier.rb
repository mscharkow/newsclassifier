class AddLearningClassifier < ActiveRecord::Migration
  def change
    add_column :classifiers, :teacher_id, :integer
  end
end
