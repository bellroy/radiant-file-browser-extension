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
  
  #####

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
    version  = AssetLock.lock_version
    post :remove, :id => path2id(test_dir), :version => version    
    response.should redirect_to(files_path)    
    Pathname.new(test_dir).should_not be_exist
  end

  it "should remove the file when confirmed" do
    test_file = File.join(FileBrowserExtension.asset_path, @renamed_test_upload_file)
    version  = AssetLock.lock_version
    post :remove, :id => path2id(test_file), :version => version 
    response.should redirect_to(files_path)    
    Pathname.new(test_file).should_not be_exist
  end    
  
  ####

  it "should not allow directory to be edited if a new directory is added" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}    
    initial_version = AssetLock.lock_version
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @second_test_dir}    
    post :edit, :id => path2id(test_dir), :version => initial_version, :file_name => @renamed_test_dir   
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_dir)).rmdir    
  end

  it "should not allow filename to be edited if a new file is added" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    initial_version = AssetLock.lock_version
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)    
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@second_test_upload_file, "image/jpg")}
    post :edit, :id => path2id(test_file), :version => initial_version, :file_name => @renamed_test_upload_file
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_upload_file)).delete
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_upload_file)).delete     
  end

  it "should not allow directory to be edited if a directory has been removed" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @second_test_dir} 
    initial_version = AssetLock.lock_version
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    second_test_dir = File.join(FileBrowserExtension.asset_path, @second_test_dir)    
    post :remove, :id => path2id(second_test_dir), :version => initial_version 
    post :edit, :id => path2id(test_dir), :version => initial_version, :file_name => @renamed_test_dir   
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir        
  end

  it "should not allow filename to be edited if a file has been removed" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@second_test_upload_file, "image/jpg")}
    initial_version = AssetLock.lock_version
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)    
    second_test_file = File.join(FileBrowserExtension.asset_path, @second_test_upload_file)    
    post :remove, :id => path2id(second_test_file), :version => initial_version 
    post :edit, :id => path2id(test_file), :version => initial_version, :file_name => @renamed_test_upload_file  
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be edited."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_upload_file)).delete
  end

  ####

  it "should not allow directory to be deleted if a new directory is added" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}    
    initial_version = AssetLock.lock_version
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @second_test_dir}    
    post :remove, :id => path2id(test_dir), :version => initial_version
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_dir)).rmdir  
  end

  it "should not allow file to be deleted if a new file is added" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}   
    initial_version = AssetLock.lock_version
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)    
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@second_test_upload_file, "image/jpg")}
    post :remove, :id => path2id(test_file), :version => initial_version
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_upload_file)).delete
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_upload_file)).delete
  end

  it "should not allow directory to be deleted if another directory has been deleted" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir}    
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @second_test_dir}
    initial_version = AssetLock.lock_version
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    second_test_dir = File.join(FileBrowserExtension.asset_path, @second_test_dir)  
    post :remove, :id => path2id(test_dir), :version => initial_version 
    post :remove, :id => path2id(second_test_dir), :version => initial_version 
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should be_success
    second_version = AssetLock.lock_version
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_dir)).rmdir
  end

  it "should not allow file to be deleted if another file has been deleted" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@second_test_upload_file, "image/jpg")}
    initial_version = AssetLock.lock_version
    test_file = File.join(FileBrowserExtension.asset_path, @test_upload_file)     
    second_test_file = File.join(FileBrowserExtension.asset_path, @second_test_upload_file)    
    post :remove, :id => path2id(test_file), :version => initial_version
    post :remove, :id => path2id(second_test_file), :version => initial_version   
    flash[:error].to_s.should == "The assets have been modified since it was last loaded hence could not be deleted."
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @second_test_upload_file)).delete
  end

  ####

  it "should render children via AJAX" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir} 
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    xml_http_request :post, :children, :id => path2id(test_dir), :level => '1'    
    response.should be_success
    response.body.should_not have_text('<head>')
    response.content_type.should == 'text/html'
    response.charset.should == 'utf-8'
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
  end

  it "should show new asset page when Add Child is clicked" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir} 
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    parent_id = path2id(test_dir)
    get :new, :parent_id => parent_id
    response.should be_success
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
  end

  it "should create a child directory within another directory" do
    version = AssetLock.lock_version
    post :new, :parent_id => '', :new_type => 'CREATE', :version => version, :asset => {:directory_name => @test_dir}
puts "VERSION-" + version.to_s + "-Parent ID-"
    test_dir = File.join(FileBrowserExtension.asset_path, @test_dir)    
    parent_id = path2id(test_dir)
    post :new, :parent_id => parent_id, :new_type => 'CREATE', :version => version, :asset => {:directory_name => @second_test_dir}
puts "VERSION-" + version.to_s + "-Parent ID-"
    response.should redirect_to(files_path)
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir, @second_test_dir)).rmdir
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
   end

  it "should not create a directory if the directory aleady exists" do
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir} 
    post :new, :parent_id => nil, :new_type => 'CREATE', :asset => {:directory_name => @test_dir} 
    flash[:error].to_s.should == "Directory already exists."
    response.should redirect_to(files_path)
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_dir)).rmdir
  end

  it "should not create a file if file already exists" do
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    post :new, :parent_id => nil, :new_type => 'UPLOAD', :asset => {:uploaded_data => fixture_file_upload(@test_upload_file, "image/jpg")}
    flash[:error].to_s.should == "Filename already exists."
    response.should redirect_to(files_path)
    Pathname.new(File.join(FileBrowserExtension.asset_path, @test_upload_file)).delete
  end

end
