require 'spec_helper'

describe Classifier do
  before(:each) do
    @cl = FactoryGirl.create(:classifier)
  end

  it { should have_many(:categories) }
  it { should have_many(:classifications) }
  it { should have_many(:documents) }
    
  it "should be valid from factory" do
     @cl.valid?
  end
end
