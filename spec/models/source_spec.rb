require 'spec_helper'

describe Source do
  before(:each) do
    @s = FactoryGirl.create(:source)
  end 

  it { should belong_to(:project) }
  it { should have_many(:documents) }

  it "should be valid from factory" do
    @s.valid?
  end
  
  it "should find valid feed" do
    @s.site_url = 'http://bbc.co.uk'
    @s.save && @s.urls?
  end
  
  it "should not find invalid feed" do
    @s.site_url = 'http://example.com'
    ! @s.save && @s.urls?
  end
  
end
