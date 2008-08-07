require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::FileHelper do
  scenario :users  
  
  before do
    create_dir('Test', nil)
  end

  before :each do
    login_as :admin
  end  
  
  it "should display a directory" 
  
  it "should display a file" 
  
  
end
