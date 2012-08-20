project = Project.create!(name:'NewsClassifier Demo',permalink:'demo') and
user = project.users.create!(:email=>'ncdemo@example.org',:password=>"ncdemo") and user.update_attribute(:admin,true)