require 'spec_helper'

describe DictionaryClassifier do
  before(:each) do
    @cl = FactoryGirl.create(:dictionary_classifier)
    @cl.regexp = '/test/i'
  end

  it { should have_many(:categories) }
  it { should have_many(:classifications) }
  it { should have_many(:documents) }
    
  it "should be valid from factory" do
     @cl.valid?
  end
  
  it "should classify a document by title" do
    doc_1 = FactoryGirl.create(:document,:title=>'test document')
    @cl.classify(doc_1).code.should == 1
    
    doc_0 = FactoryGirl.create(:document,:title=>'Foo document')
    @cl.classify(doc_0).code.should == 0
  end
  
  it "should classify a document by content" do
    doc_1 = FactoryGirl.create(:document,:title=>'Test document')
    doc_1.update_body(:content => 'Test content')
    doc_1.content.should match(/content/i)
    @cl.classify(doc_1).code.should == 2
    
    doc_0 = FactoryGirl.create(:document)
    doc_0.body.update_attributes(:content=> 'Foo Document')
    @cl.classify(doc_0).code.should == 0
  end
  
  it "should classify using a regex string" do
    @cl.regexp = 'document'
    doc_1 = FactoryGirl.create(:document,:title=>'Document')
    @cl.classify(doc_1).code.should == 1
    
    doc_2 = FactoryGirl.create(:document,:title=>'document')
    @cl.classify(doc_2).code.should == 1
    
    doc_3 = FactoryGirl.create(:document,:title=>'foo')
    @cl.classify(doc_3).code.should == 0
  end
  
  it "should ignore irrelevant parts" do
    @cl.parts = %w(content)
    doc_1 = FactoryGirl.create(:document,:title=>'test document')
    doc_1.update_body(:content =>'Test Document')
    @cl.classify(doc_1).code.should == 1
    
    doc_0 = FactoryGirl.create(:document,:title=>'test document')
    @cl.classify(doc_0).code.should == 0
  end
  
  it 'should save classification when required' do
    doc_1 = FactoryGirl.create(:document,:title=>'test document')
    @cl.classifications.count.should == 0
    @cl.classify(doc_1)
    @cl.reload.classifications.count.should == 0
    @cl.classify(doc_1,true)
    @cl.reload.classifications.count.should == 1
    @cl.classify(doc_1,true)
    @cl.reload.classifications.count.should == 1
  end
  
end
