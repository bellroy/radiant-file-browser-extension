require File.dirname(__FILE__) + '/../../spec_helper'
include DirectoryArray

describe Admin::FileController do
  scenario :users

  before do
    @test_dir = 'Test1' 
    @test_upload_file = 'test_image.jpg'
  end

  before :each do
    login_as :admin
  end
     
  it "should insert an admin tab" do
    Radiant::AdminUI.instance.tabs.any? {|tab| tab.name == "Assets"}.should be_true
  end

  it "should render asset index page" do
    get :index
    response.should be_success
  end
  
  it "should render new asset page" do
    get :new 
    response.should be_success    
  end
  
  it "should create a directory" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}
    response.should redirect_to(files_path)          
  end
  
  it "should create upload files" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload("../../vendor/extensions/file_browser/spec/fixtures/" + @test_upload_file, "image/jpg")}
    response.should redirect_to(files_path) 
  end  
  
  it "should display confirmation page when clicked on remove for a directory" do
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)
    get :remove, :id => path2id(test_dir)
    response.should be_success    
  end

  it "should display confirmation page when clicked on remove for a file" do
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)
    get :remove, :id => path2id(test_file)
    response.should be_success     
  end
  
  it "should redirect to index when id is not passed to remove" do
    get :remove, :id => nil
    response.should redirect_to(files_path)       
    get :remove, :id => ''
    response.should redirect_to(files_path)      
  end

  it "should remove the directory when confirmed" do
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)
    post :remove, :id => path2id(test_dir)    
    response.should redirect_to(files_path)    
  end

  it "should remove the file when confirmed" do
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)
    post :remove, :id => path2id(test_file)
    response.should redirect_to(files_path)    
  end
  

end
