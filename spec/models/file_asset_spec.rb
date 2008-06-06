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
  end

  it "should create a filename" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    file_asset.success.should == true
  end

  it "should rename a filename" do
    file_asset = FileAsset.update(path2id(full_path(@test_upload_file)), @renamed_test_upload_file, get_current_lock)
    file_asset.success.should == "Filename has been sucessfully edited."
  end 

  it "should remove a file" do
    FileAsset.destroy(path2id(full_path(@renamed_test_upload_file)), get_current_lock).should == true
  end

  it "should not create a file if it has a / \\ or leading period" do

  end

  it "should not upload a file if file already exists" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    file_asset.success.should == false
    file_asset.errors.should == ["Filename already exists."]
    FileAsset.destroy(path2id(full_path(@test_upload_file)), get_current_lock)
  end

  it "should not upload a file if version mismatch occurs" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, (get_current_lock + 1))
    file_asset.success.should == false
    file_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be created."] 
  end

  it "should not edit file if it has a / \\ or leading period" do

  end


  it "should not update if file already exists" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    file_asset = FileAsset.create(fixture_file_upload(@second_test_upload_file, "image/jpg"), nil, get_current_lock)
    id = path2id(full_path(@test_upload_file))
    file_asset = FileAsset.update(id, @second_test_upload_file, get_current_lock)

    file_asset.success.should == false
    file_asset.errors.should == ["Filename already exists."]
    FileAsset.destroy(path2id(full_path(@test_upload_file)), get_current_lock)    
    FileAsset.destroy(path2id(full_path(@second_test_upload_file)), get_current_lock)    
  end

  it "should not update file if version mismatch occurs" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    id = path2id(full_path(@test_upload_file))
    file_asset = FileAsset.update(id, @second_test_upload_file, (get_current_lock + 1))
    file_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be edited."]
    FileAsset.destroy(path2id(full_path(@test_upload_file)), get_current_lock)  
  end

  it "should not remove file if version mismatch occurs" do
    file_asset = FileAsset.create(fixture_file_upload(@test_upload_file, "image/jpg"), nil, get_current_lock)
    id = path2id(full_path(@test_upload_file))
    FileAsset.destroy(id, (get_current_lock + 1)).should == false
    FileAsset.destroy(id, get_current_lock).should == true
  end

end
