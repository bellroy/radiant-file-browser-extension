require File.dirname(__FILE__) + '/../spec_helper'

def get_absolute_root_path
    FileBrowserExtension.asset_path
end

def full_path(dirname)
    File.join(get_absolute_root_path, dirname)
end

def get_current_lock
    AssetLock.lock_version
end

describe FileAsset do
  before do
    @test_upload_file = 'test_image.jpg'
    @renamed_test_upload_file = 'test_image_new.jpg'
    @second_test_upload_file = 'test_image2.jpg'
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    @file = FileAsset.new
  end
  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end
    
  it "should be not be valid if there are errors"
  it "should not save the asset to the filesystem if it is invalid"

  describe 'filesystem CRUD' do
    it "should create a file" do
      file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
      file_asset.success.should == true
    end

    it "should rename a file" do
      file_asset = FileAsset.update(path2id(full_path(@test_upload_file)), @renamed_test_upload_file, get_current_lock)
      file_asset.success.should == "Filename has been sucessfully edited."
    end 

    it "should remove a file" do
      FileAsset.destroy(path2id(full_path(@renamed_test_upload_file)), get_current_lock).should == true
    end
  end

  it 'should report the extension of the filename' do
    @file.stub!(:name).and_return('file.jpg')
    
    @file.extension.should == 'jpg'
  end

  describe 'type' do
    it 'should identify as image if extension is png' do
      @file.stub!(:extension).and_return('png')
      
      @file.image?.should be_true
    end
    it 'should identify as image if extension is jpg'
    it 'should identify as image if extension is jpeg'
    it 'should identify as image if extension is gif'
    it 'should identify as image if extension is bmp'
    
    it 'should identify as image ignoring extension case' do
      @file.stub!(:extension).and_return('PnG')
      
      @file.image?.should be_true
    end
    
    it 'should identify as non-image if has no extension' do
      @file.stub!(:extension).and_return('')
      
      @file.image?.should be_false
    end
    it 'should identify as non-image if extension is not recognised image type'
  end
  
  describe 'embed tag' do
    it 'should give img src if is an image' do
      @file.stub!(:image?).and_return(true)
      
      @file.embed_tag.should start_with('<img src=')
    end
    
    it 'should give a if not an image' do
      @file.stub!(:image?).and_return(false)
      
      @file.embed_tag.should start_with('<a href=')
    end
    
    it 'should point to file location in uri' do
      @file.stub(:image?).and_return(true)
      FileAsset.public_asset_path.stub!('assets')
      @file.stub(:name).and_return('filename')
      
      @file.embed_tag.should == "<img src='assets/filename'>"
    end
  end

  describe "name" do
    it "should have an error if contains backslash characters"
    it "should have an error if contains forwardslash characters"
    it "should have an error if contains fullstop characters"
    
    it "should have an error if already in use" do
      file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
      file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
      file_asset.success.should == false
      file_asset.errors.should == ["Filename already exists."]
      FileAsset.destroy(path2id(full_path(@test_upload_file)), get_current_lock)
    end
  end

  describe 'on version mismatch' do
    it 'should not upload' do
      file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, (get_current_lock + 1))
      file_asset.success.should == false
      file_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be created."] 
    end
    
    it "should not remove" do
      file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
      id = path2id(full_path(@test_upload_file))
      FileAsset.destroy(id, (get_current_lock + 1)).should == false
      FileAsset.destroy(id, get_current_lock).should == true
    end
  end

  it "should not update file if version mismatch occurs" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    id = path2id(full_path(@test_upload_file))
    file_asset = FileAsset.update(id, @second_test_upload_file, (get_current_lock + 1))
    file_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be edited."]
    FileAsset.destroy(path2id(full_path(@test_upload_file)), get_current_lock)  
  end

end
