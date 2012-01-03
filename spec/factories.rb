FactoryGirl.define do  
  factory :user do |u|    
    u.email 'username@example.com'
    u.password 'valid_password'
    u.association :project
  end
  
  factory :project do |p|
    p.name  'Test Project'
    p.sequence(:permalink) {|n| "permalink#{n}" }
  end
  
  factory :source do |s|
    s.name   'Test Source'
    s.association :project
  end
  
  factory :document do |d|
    d.title   'The title'
    d.association :source
  end
  
  factory :body do |b|
    b.association :document
  end
    
  factory :category do |cat|
    cat.name  'Test category'
    cat.association :classifier
  end
  
  factory :dictionary_classifier do |cl|
    cl.name 'Test dict'
    cl.regexp '/test/i'
    cl.parts %w(title summary content)
    cl.association :project
  end
  
  factory :classifier do |cl|
    cl.name   'Test classifier'
    cl.parts %w(title summary content)
    cl.association :project
  end
  
  factory :classifier_with_categories, :parent => :classifier do |cl|
    cl.name   'Test classifier with categories'
    cl.association :project
    cl.after_build { |cl| 
        2.times {|i| Factory(:category,:classifier=>cl)}
      }
  end
  
  factory :classification do |cl|
    cl.association :category
    cl.association :document
  end
end