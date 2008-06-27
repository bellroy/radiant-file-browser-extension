require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

def get_absolute_root_path
    FileBrowserExtension.asset_path
end

def full_path(dirname)
    File.join(get_absolute_root_path, dirname)
end

def get_current_lock
    AssetLock.lock_version
end

def create_dir(dirname, parent_id, version=get_current_lock)
    post :new, :parent_id => parent_id, :new_type => 'CREATE', :asset => {:directory_name => dirname}, :version => version, :v => get_current_lock
end

def create_file(filename, parent_id=nil)
    post :new, :parent_id => parent_id, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(filename, "image/jpg")}, :version => get_current_lock, :v => get_current_lock
end

def rename_asset(oldname, newname, version=get_current_lock)
    post :edit, :id => path2id(full_path(oldname)), :version => version, :file_name => newname, :version => version, :v => get_current_lock
end

def remove_asset(assetname, version=get_current_lock)
    post :remove, :id => path2id(full_path(assetname)), :version => version, :v => get_current_lock
end


describe Admin::FileController do
  scenario :users  

  before do
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    @test_dir = 'Test1' 
    @test_upload_file = 'test_image.jpg'
    @renamed_test_dir = 'Test1_new'
    @renamed_test_upload_file = 'test_image_new.jpg'
    @second_test_dir = 'Test2'
    @second_test_upload_file = 'test_image2.jpg'
  end
  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
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
    get :new, :v => get_current_lock
    response.should be_success    
  end
  
  it "should create a directory" do
    create_dir(@test_dir, nil)
    response.should redirect_to(files_path)          
  end

  it "should create upload files" do
    create_file(@test_upload_file)
    response.should redirect_to(files_path) 
  end  
   
  it "should display edit page if clicked on edit link for directory" do
    get :edit, :id => path2id(full_path(@test_dir)), :version => get_current_lock, :v => get_current_lock
    response.should be_success        
  end
  
  it "should display edit page if clicked on edit link for file" do
    get :edit, :id => path2id(full_path(@test_upload_file)), :version => get_current_lock, :v => get_current_lock
    response.should be_success        
  end
  
  it "should display confirmation page when clicked on remove for a directory" do
    get :remove, :id => path2id(full_path(@test_dir)), :version => get_current_lock, :v => get_current_lock
    response.should be_success    
  end

  it "should rename the directory" do
    rename_asset(@test_dir, @renamed_test_dir)
    flash[:notice].to_s.should == "Directory has been sucessfully edited." 
    response.should redirect_to(files_path) 
  end

  it "should rename the file" do
    rename_asset(@test_upload_file, @renamed_test_upload_file)
    flash[:notice].to_s.should == "Filename has been sucessfully edited." 
    response.should redirect_to(files_path)
  end

  #####

  it "should display confirmation page when clicked on remove for a file" do
    get :remove, :id => path2id(full_path(@renamed_test_upload_file)), :version => get_current_lock, :v => get_current_lock
    response.should be_success     
  end
  
  it "should redirect to index when id is not passed to remove" do
    get :remove, :id => nil, :version => get_current_lock, :v => get_current_lock
    flash[:error].to_s.should == "An error occured. Possibly the id field was not supplied."
    response.should redirect_to(files_path)       

    get :remove, :id => '', :version => get_current_lock, :v => get_current_lock
    flash[:error].to_s.should == "An error occured. Possibly the id field was not supplied."
    response.should redirect_to(files_path)

    post :remove, :id =>  nil, :version => get_current_lock, :v => get_current_lock
    flash[:error].to_s.should == "An error occured. Possibly the id field was not supplied."
    response.should redirect_to(files_path)      

    post :remove, :id => '', :version => get_current_lock, :v => get_current_lock
    flash[:error].to_s.should == "An error occured. Possibly the id field was not supplied."
    response.should redirect_to(files_path)
  end
   
  it "should remove the directory when confirmed" do
    remove_asset(@renamed_test_dir)
    flash[:notice].to_s.should == "The directory was successfully removed from the assets."
    response.should redirect_to(files_path)       
    Pathname.new(full_path(@renamed_test_dir)).should_not be_exist
  end

  it "should remove the file when confirmed" do
    remove_asset(@renamed_test_upload_file)
    flash[:notice].to_s.should == "The file was successfully removed from the assets."
    response.should redirect_to(files_path)       
    Pathname.new(full_path(@renamed_test_upload_file)).should_not be_exist
  end    

  ####

  it "should not allow directory to be edited if a new directory is added" do
    create_dir(@test_dir, nil)
    initial_version = AssetLock.lock_version
    create_dir(@second_test_dir, nil)
    rename_asset(@test_dir, @renamed_test_dir, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should redirect_to(files_path)       
    remove_asset(@test_dir)    
    remove_asset(@second_test_dir)
  end

  it "should not allow filename to be edited if a new file is added" do
    create_file(@test_upload_file)
    initial_version = AssetLock.lock_version    
    create_file(@second_test_upload_file)
    rename_asset(@test_upload_file, @renamed_test_upload_file, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should redirect_to(files_path)       
    remove_asset(@test_upload_file)    
    remove_asset(@second_test_upload_file)     
  end
  
  it "should not allow directory to be edited if a directory has been removed" do
    create_dir(@test_dir, nil)
    create_dir(@second_test_dir, nil)
    initial_version = AssetLock.lock_version  
    remove_asset(@second_test_dir) 
    rename_asset(@test_dir, @renamed_test_dir, initial_version)   
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should redirect_to(files_path)       
    remove_asset(@test_dir)       
  end

  it "should not allow filename to be edited if a file has been removed" do
    create_file(@test_upload_file)
    create_file(@second_test_upload_file)
    initial_version = AssetLock.lock_version   
    remove_asset(@second_test_upload_file)
    rename_asset(@test_upload_file, @renamed_test_upload_file, initial_version)  
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should redirect_to(files_path)       
    remove_asset(@test_upload_file)
  end

  ####

  it "should not allow directory to be deleted if a new directory is added" do
    create_dir(@test_dir, nil)
    initial_version = AssetLock.lock_version
    create_dir(@second_test_dir, nil)
    remove_asset(@test_dir, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should redirect_to(files_path)       
    remove_asset(@test_dir)
    remove_asset(@second_test_dir)
  end

  it "should not allow file to be deleted if a new file is added" do
    create_file(@test_upload_file)
    initial_version = AssetLock.lock_version   
    create_file(@second_test_upload_file)
    remove_asset(@test_upload_file, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should redirect_to(files_path)       
    remove_asset(@test_upload_file)
    remove_asset(@second_test_upload_file)
  end

  it "should not allow directory to be deleted if another directory has been deleted" do
    create_dir(@test_dir, nil)
    create_dir(@second_test_dir, nil)
    initial_version = AssetLock.lock_version 
    remove_asset(@test_dir, initial_version)
    remove_asset(@second_test_dir, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should redirect_to(files_path)       
    remove_asset(@second_test_dir)
  end

  it "should not allow file to be deleted if another file has been deleted" do
    create_file(@test_upload_file)
    create_file(@second_test_upload_file)
    initial_version = AssetLock.lock_version
    remove_asset(@test_upload_file, initial_version)
    remove_asset(@second_test_upload_file, initial_version)   
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should redirect_to(files_path)       
    remove_asset(@second_test_upload_file)   
  end

  ####

  it "should render children via AJAX" do
    create_dir(@test_dir, nil)
    xml_http_request :post, :children, :id => path2id(full_path(@test_dir)), :level => '1'    
    response.should be_success
    response.body.should_not have_text('<head>')
    response.content_type.should == 'text/html'
    response.charset.should == 'utf-8'
    remove_asset(@test_dir)
  end

  it "should show new asset page when Add Child is clicked" do
    create_dir(@test_dir, nil)
    parent_id = path2id(full_path(@test_dir))
    get :new, :parent_id => parent_id, :v => get_current_lock
    response.should be_success
    remove_asset(@test_dir)
  end

  it "should create a child directory within another directory" do
    create_dir(@test_dir, nil)
    parent_id = path2id(full_path(@test_dir))
    create_dir(@second_test_dir, parent_id)
    response.should redirect_to(files_path)
    remove_asset(@test_dir)
    remove_asset(@second_test_dir)
  end

  it "should not create a child directory if a directory meanwhile as been added" do
    create_dir(@test_dir, nil)
    initial_version = AssetLock.lock_version
    parent_id = path2id(full_path(@test_dir))
    create_dir(@second_test_dir, nil) 
    create_dir(@renamed_test_dir, parent_id, initial_version)
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be created."
    response.should redirect_to(files_path)       
    remove_asset(@test_dir)
    remove_asset(@second_test_dir)
  end

  it "should not create a directory if the directory aleady exists" do
    create_dir(@test_dir, nil)
    create_dir(@test_dir, nil)
    flash[:error].to_s.should == "Directory already exists."
    response.should redirect_to(files_path)       
    remove_asset(@test_dir)
  end

  it "should not create a file if file already exists" do
    create_file(@test_upload_file)
    create_file(@test_upload_file)
    flash[:error].to_s.should == "Filename already exists."
    response.should  redirect_to(files_path)       
    remove_asset(@test_upload_file)
  end

end
