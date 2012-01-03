require 'spec_helper'

describe Body do
  before(:each) do
    @b = FactoryGirl.create(:body)
  end

  it { should belong_to :document}
  
  it "should be valid from factory" do
    @b.valid?
  end
end
