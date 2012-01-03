require 'spec_helper'

describe Classification do
  before(:each) do
    @cl = Factory(:classification)
  end

  it { should belong_to(:classifier) }
  it { should belong_to(:document) }

  it "should be valid from factory" do
    @cl.valid?
  end
end
