require 'spec_helper'

describe Document do
  before(:each) do
    @doc = FactoryGirl.create(:document)
  end

  it { should validate_presence_of(:title) }
  it { should belong_to(:source) }
  it { should have_many(:classifications) }
  it { should have_many(:categories) }
  it { should have_one(:body)}
 
  it "should be valid from factory" do
    @doc.valid?
  end
  
  it "should have a body when created" do
    assert @doc.body
  end
  
  it "should provide a full text" do
    @doc.title = "test title"
    @doc.title.match('test title')
    @doc.update_body(:content=>'This is the test content')
    @doc.fulltext.should match('test content')
    @doc.fulltext.should_not match('foo content')
  end
  
end
