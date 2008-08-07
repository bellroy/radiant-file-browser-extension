require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'
 
def get_absolute_root_path
  FileBrowserExtension.asset_path
end
 
def full_path(dirname)
  File.join(get_absolute_root_path, dirname)
end
 
def current_version
  AssetLock.lock_version
end
 
def error_message(err_type)
  [:modified, :unknown, :blankid].include?(err_type) ? Asset::Errors::CLIENT_ERRORS[err_type] : "Asset name " + Asset::Errors::CLIENT_ERRORS[err_type]
end
 
def create_dir(dirname, parent_id, version=current_version)
  post :new, :asset => {:name => dirname, :parent_id => parent_id, :new_type => 'Directory', :version => version}, :v => version
end
 
def create_file(filename, parent_id=nil)
  post :new, :asset => {:uploaded_data => fixture_file_upload(filename, "image/jpg"), :parent_id => parent_id, :new_type => 'File', :version => current_version}, :v => current_version
end
 
def rename_asset(oldname, newname, version=current_version)
  post :edit, :id => path2id(full_path(oldname)), :asset => {:name => newname}, :v => version
end
 
def remove_asset(assetname, version=current_version)
  post :remove, :id => path2id(full_path(assetname)), :v => version
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
 
  describe "Create Direcotory/Upload file" do
 
    before do
 
    end
 
    it "should render new asset page" do
      get :new, :v => current_version
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
 
    it "should show new asset page when Add Child is clicked" do
      create_dir(@test_dir, nil)
      parent_id = path2id(full_path(@test_dir))
      get :new, :parent_id => parent_id, :v => current_version
      response.should be_success
    end
 
    it "should create a child directory within another directory" do
      create_dir(@test_dir, nil)
      parent_id = path2id(full_path(@test_dir))
      post :new, :asset => {:name => @second_test_dir, :parent_id => parent_id, :version => current_version, :new_type => 'Directory'}, :v => current_version
      response.should redirect_to(files_path)
    end
 
    it "should not create a child directory if a directory meanwhile has been added" do
      create_dir(@test_dir, nil)
      initial_version = AssetLock.lock_version
      parent_id = path2id(full_path(@test_dir))
      create_dir(@second_test_dir, nil)
      create_dir(@renamed_test_dir, parent_id, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
    it "should not create a child directory if a file meanwhile has been added"
    it "should not create a child directory if a directory meanwhile has been edited"
    it "should not create a child directory if a directory meanwhile has been removed"
    it "should not create a child directory if a file meanwhile has been edited"
    it "should not create a child directory if a file meanwhile has been removed"
 
    it "should not open the Add Child page if an asset is added meanwhile" do
      create_dir(@test_dir, nil)
      initial_lock = AssetLock.lock_version
      create_dir(@second_test_dir, nil)
      parent_id = path2id(full_path(@test_dir))
      get :new, :parent_id => parent_id, :v => initial_lock
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
    it "should not open the Add Child page if a file meanwhile has been added"
    it "should not open the Add Child page if a directory meanwhile has been edited"
    it "should not open the Add Child page if a directory meanwhile has been removed"
    it "should not open the Add Child page if a file meanwhile has been edited"
    it "should not open the Add Child page if a file meanwhile has been removed"
 
    it "should not create a directory if the directory aleady exists" do
      create_dir(@test_dir, nil)
      create_dir(@test_dir, nil)
      flash[:error].to_s.should == error_message(:exists)
      response.should be_success
    end
 
    it "should not create a child directory if the child directory already exists"
 
    it "should not create a file if file already exists" do
      create_file(@test_upload_file)
      create_file(@test_upload_file)
      flash[:error].to_s.should == error_message(:exists)
      response.should be_success
    end
 
    it "should not create a child file if child file already exists"
 
  end
 
 
  describe "Editing of Directory/filenames" do
 
    before do
      create_dir(@test_dir, nil)
      create_file(@test_upload_file)
    end
 
    it "should display edit page if clicked on edit link for directory" do
      get :edit, :id => path2id(full_path(@test_dir)), :version => current_version, :v => current_version
      response.should be_success
    end
 
    it "should display edit page if clicked on edit link for file" do
      get :edit, :id => path2id(full_path(@test_upload_file)), :version => current_version, :v => current_version
      response.should be_success
    end
 
    it "should rename the directory" do
      rename_asset(@test_dir, @renamed_test_dir)
      flash[:notice].to_s.should == "Folder name has been successfully edited."
      response.should redirect_to(files_path)
    end
 
    it "should rename the file" do
      rename_asset(@test_upload_file, @renamed_test_upload_file)
      flash[:notice].to_s.should == "Image name has been successfully edited."
      response.should redirect_to(files_path)
    end
 
    it "should not allow directory to be edited if a new directory is added" do
      initial_version = AssetLock.lock_version
      create_dir(@second_test_dir, nil)
      rename_asset(@test_dir, @renamed_test_dir, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow filename to be edited if a new file is added" do
      initial_version = AssetLock.lock_version
      create_file(@second_test_upload_file)
      rename_asset(@test_upload_file, @renamed_test_upload_file, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow directory to be edited if a directory has been removed" do
      create_dir(@second_test_dir, nil)
      initial_version = AssetLock.lock_version
      remove_asset(@second_test_dir)
      rename_asset(@test_dir, @renamed_test_dir, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow filename to be edited if a file has been removed" do
      create_file(@second_test_upload_file)
      initial_version = AssetLock.lock_version
      remove_asset(@second_test_upload_file)
      rename_asset(@test_upload_file, @renamed_test_upload_file, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow directory to be renamed to an existing directory name" do
      create_dir(@second_test_dir, nil)
      rename_asset(@test_dir, @second_test_dir, current_version)
      flash[:error].to_s.should == error_message(:exists)
      response.should be_success
    end
 
    it "should not allow child directory to be renamed to an existing child directory name"
 
    it "should not allow file to be renamed to an existing filename" do
      create_file(@second_test_upload_file)
      rename_asset(@test_upload_file, @second_test_upload_file, current_version)
      flash[:error].to_s.should == error_message(:exists)
      response.should be_success
    end
 
    it "should not allow child file to be renamed to an existing child filename"
 
  end
 
  describe "Removing of Directory/files" do
 
    before do
      create_dir(@test_dir, nil)
      create_file(@test_upload_file)
    end
 
    it "should display confirmation page when clicked on remove for a directory" do
      get :remove, :id => path2id(full_path(@test_dir)), :version => current_version, :v => current_version
      response.should be_success
    end
 
    it "should display confirmation page when clicked on remove for a file" do
      get :remove, :id => path2id(full_path(@test_upload_file)), :version => current_version, :v => current_version
      response.should be_success
    end
 
    it "should redirect to index when id is not passed to remove" do
      get :remove, :id => nil, :version => current_version, :v => current_version
      flash[:error].to_s.should == error_message(:blankid)
      response.should redirect_to(files_path)
 
      get :remove, :id => '', :version => current_version, :v => current_version
      flash[:error].to_s.should == error_message(:blankid)
      response.should redirect_to(files_path)
 
      post :remove, :id => nil, :version => current_version, :v => current_version
      flash[:error].to_s.should == error_message(:blankid)
      response.should redirect_to(files_path)
 
      post :remove, :id => '', :version => current_version, :v => current_version
      flash[:error].to_s.should == error_message(:blankid)
      response.should redirect_to(files_path)
    end
 
    it "should remove the directory when confirmed" do
      remove_asset(@test_dir)
      flash[:notice].to_s.should == "The asset was successfully removed."
      response.should redirect_to(files_path)
      Pathname.new(full_path(@test_dir)).should_not be_exist
    end
 
    it "should remove the file when confirmed" do
      remove_asset(@test_upload_file)
      flash[:notice].to_s.should == "The asset was successfully removed."
      response.should redirect_to(files_path)
      Pathname.new(full_path(@test_upload_file)).should_not be_exist
    end
 
    it "should not allow directory to be deleted if a new directory is added" do
      initial_version = AssetLock.lock_version
      create_dir(@second_test_dir, nil)
      remove_asset(@test_dir, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow file to be deleted if a new file is added" do
      initial_version = AssetLock.lock_version
      create_file(@second_test_upload_file)
      remove_asset(@test_upload_file, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow directory to be deleted if another directory has been deleted" do
      create_dir(@second_test_dir, nil)
      initial_version = AssetLock.lock_version
      remove_asset(@test_dir, initial_version)
      remove_asset(@second_test_dir, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
    it "should not allow file to be deleted if another file has been deleted" do
      create_file(@second_test_upload_file)
      initial_version = AssetLock.lock_version
      remove_asset(@test_upload_file, initial_version)
      remove_asset(@second_test_upload_file, initial_version)
      flash[:error].to_s.should == error_message(:modified)
      response.should redirect_to(files_path)
    end
 
  end
  
  describe 'list' do
    MAX_EMPTY_TIME = 0.05
    it "should take < #{MAX_EMPTY_TIME} seconds to run on empty asset directory" do
      time_taken_to{ get(:index) }.should <= MAX_EMPTY_TIME
    end
    # all this is doing is calling Asset.root , that should be fast
    MAX_FULL_TIME = 0.1
    it "should take < #{MAX_FULL_TIME} seconds to run on empty populated directory" do
      begin
        create_lots_of_files
        time_taken_to{ get(:index) }.should <= MAX_FULL_TIME
      ensure
        delete_those_lots_of_files
      end
    end
  end
 
  #####
  #TODO: Both the below specs needs to be corrected
  describe "managing AJAX request" do
 
    it "should render children via AJAX" do
      create_dir(@test_dir, nil)
      xml_http_request :post, :children, :id => path2id(full_path(@test_dir)), :level => '1', :asset_lock => current_version
      response.should be_success
      response.body.should_not have_text('<head>')
      response.content_type.should == 'text/html'
      response.charset.should == 'utf-8'
    end
 
    it "should render error message via AJAX" do
      create_dir(@test_dir, nil)
      xml_http_request :post, :children, :id => path2id(full_path(@test_dir)), :level => '1', :asset_lock => (current_version - 1)
      response.should be_success
      response.body.should_not have_text('<head>')
      response.content_type.should == 'text/html'
      response.charset.should == 'utf-8'
    end
 
  end
end
