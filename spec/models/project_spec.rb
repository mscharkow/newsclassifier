require 'spec_helper'

describe Project do
  before(:each) do
    @p = FactoryGirl.create(:project)
  end
  
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:permalink).with_message(/one/) }
  it { should validate_uniqueness_of(:permalink).with_message(/unique/) }
  it { should have_many(:classifiers) }
  it { should have_many(:sources) }
  it { should have_many(:users) }
    
  it "should create a new instance given valid attributes" do
    @p.valid?
  end
end
