require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::FileController do
  scenario :users  

  before do
    @test_dir = 'Test1' 
    @test_upload_file = 'test_image.jpg'
    @renamed_test_dir = 'Test1_new'
    @renamed_test_upload_file = 'test_image_new.jpg'
    @second_test_dir = 'Test2'
    @second_test_upload_file = 'test_image2.jpg'
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
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    response.should redirect_to(files_path) 
  end  
  
  it "should display edit page if clicked on edit link for directory" do
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    get :edit, :id => path2id(test_dir)
    response.should be_success        
  end
  
  it "should display edit page if clicked on edit link for file" do
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)    
    get :edit, :id => path2id(test_file)
    response.should be_success        
  end
  
  it "should display confirmation page when clicked on remove for a directory" do
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)
    get :remove, :id => path2id(test_dir)
    response.should be_success    
  end

  it "should rename the directory" do
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    version  = AssetLock.lock_version
    post :edit, :id => path2id(test_dir), :version => version, :file_name => @renamed_test_dir 
    flash[:notice].to_s.should == "Directory has been sucessfully edited." 
    response.should redirect_to(files_path) 
  end

  it "should rename the file" do
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)    
    version  = AssetLock.lock_version
    post :edit, :id => path2id(test_file), :version => version, :file_name => @renamed_test_upload_file
    flash[:notice].to_s.should == "Filename has been sucessfully edited." 
    response.should redirect_to(files_path)
  end
  
###############

  it "should display confirmation page when clicked on remove for a file" do
    test_file = File.join(FileBrowserExtension.asset_path, @renamed_test_upload_file)
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
    test_dir = File.join(FileBrowserExtension.asset_path, @renamed_test_dir)
    post :remove, :id => path2id(test_dir)    
    response.should redirect_to(files_path)    
  end

  it "should remove the file when confirmed" do
    test_file = File.join(FileBrowserExtension.asset_path, @renamed_test_upload_file)
    post :remove, :id => path2id(test_file)
    response.should redirect_to(files_path)    
  end    
  
#################

  it "should not allow directory to be edited if a new directory is added" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}    
    initial_version = AssetLock.lock_version
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    get :edit, :id => path2id(test_dir)
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @second_test_dir}    
    second_version = AssetLock.lock_version
    puts "VERSIONS:"+initial_version.to_s+"-"+second_version.to_s
    post :edit, :id => path2id(test_dir), :version => initial_version, :file_name => @renamed_test_dir
    puts flash[:notice].to_s    
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @renamed_test_dir)).rmdir
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_dir)).rmdir    
  end

end
