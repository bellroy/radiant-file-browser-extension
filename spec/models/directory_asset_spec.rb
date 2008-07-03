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


describe DirectoryAsset do

  before do
    @test_dir = 'Test1' 
    @renamed_test_dir = 'Test1_new'
    @second_test_dir = 'Test2'
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
  end

  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  it "should get absolute root path" do
    DirectoryAsset.get_absolute_path.should == get_absolute_root_path
  end

  it "should create a directory" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    dir_asset.success.should == true
  end

  it "should rename a directory" do
    dir_asset = DirectoryAsset.update(path2id(full_path(@test_dir)), @renamed_test_dir, get_current_lock)
    dir_asset.success.should == "Directory has been sucessfully edited."
  end 

  it "should remove a directory" do
    DirectoryAsset.destroy(path2id(full_path(@renamed_test_dir)), get_current_lock).should == true
  end

  it "should not create a directory if it has a / \\ or leading period" do
    dir_asset = DirectoryAsset.create('Abc/Pqr', nil, get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.create('Abc\Pqr', nil, get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.create('Abc/Pqr\\Xyz', nil, get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.create('.AbcPqr', nil, get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]
  end

  it "should not create a directory if directory already exists" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory already exists."]
    DirectoryAsset.destroy(path2id(full_path(@test_dir)), get_current_lock)
  end

  it "should not create a directory if version mismatch occurs" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, (get_current_lock + 1))
    dir_asset.success.should == false
    dir_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be created."]
    DirectoryAsset.destroy(path2id(full_path(@test_dir)), get_current_lock)
  end

  it "should not edit directory if it has a / \\ or leading period" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    id = path2id(full_path(@test_dir))
    dir_asset = DirectoryAsset.update(id, 'Abc/Pqr', get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.update(id, 'Abc\Pqr', get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.update(id, 'Abc/Pqr\\Xyz', get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    dir_asset = DirectoryAsset.update(id, '.AbcPqr', get_current_lock)
    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory name cannot have characters like \\ / or a leading period."]

    DirectoryAsset.destroy(path2id(full_path(@test_dir)), get_current_lock)
  end

  it "should not update if Directory already exists" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    dir_asset = DirectoryAsset.create(@second_test_dir, nil, get_current_lock)
    id = path2id(full_path(@test_dir))
    dir_asset = DirectoryAsset.update(id, @second_test_dir, get_current_lock)

    dir_asset.success.should == false
    dir_asset.errors.should == ["Directory already exists."]
    DirectoryAsset.destroy(path2id(full_path(@test_dir)), get_current_lock)    
    DirectoryAsset.destroy(path2id(full_path(@second_test_dir)), get_current_lock)    
  end

  it "should not update Directory if version mismatch occurs" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    id = path2id(full_path(@test_dir))
    dir_asset = DirectoryAsset.update(id, @second_test_dir, (get_current_lock + 1))
    dir_asset.errors.should == ["The assets have been modified since it was last loaded hence could not be edited."]
    DirectoryAsset.destroy(path2id(full_path(@test_dir)), get_current_lock)  
  end

  it "should not remove Directory if version mismatch occurs" do
    dir_asset = DirectoryAsset.create(@test_dir, nil, get_current_lock)
    id = path2id(full_path(@test_dir))
    DirectoryAsset.destroy(id, (get_current_lock + 1)).should == false
    DirectoryAsset.destroy(id, get_current_lock).should == true
  end
end
