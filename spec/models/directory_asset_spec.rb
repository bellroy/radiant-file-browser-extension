require File.dirname(__FILE__) + '/../spec_helper'

def current_version
  AssetLock.lock_version
end

def error_message(error_no)
  Asset::Errors::CLIENT_ERRORS[error_no]
end


describe DirectoryAsset do

  before do
    @test_dir = 'Test1' 
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)

    @dir_asset = DirectoryAsset.new('directory_name' => @test_dir, 'parent_id' => nil, 'version' => current_version)
    @dir_asset.save
  end

  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  it "should get absolute root path" do
    DirectoryAsset.get_absolute_path.should == absolute_path
  end

  describe "Directory Creation" do

    it "should create a directory" do
      @dir_asset.success.should == true
      Pathname.new(absolute_path(@test_dir)).directory?.should == true      
    end 

    it "should create a directory within another directory" do
      parent_id = @dir_asset.id
      dir_asset2 = DirectoryAsset.new('directory_name' => 'ChildDir', 'parent_id' => parent_id, 'version' => current_version) 
      dir_asset2.save
      dir_asset2.success.should == true
      Pathname.new(absolute_path(File.join(@test_dir, 'ChildDir'))).directory?.should == true      
    end

    fixture = [
      #consists                 assetname
      ['leading period',       '.AbcPqr'],
      ['/',                    'Abc/Pqr'],  
      ['\\',                   'Abc/Pqr\\Xyz'],
    ]

    fixture.each do |consists, name|
      it "should not create a directory if it contains #{consists} " do
        dir_asset = DirectoryAsset.new('directory_name' => name, 'parent_id' => nil, 'version' => current_version)
        dir_asset.save
        dir_asset.success.should == false
        dir_asset.errors.full_messages.should == [error_message(2)]
      end
    end
   
    it "should not create a directory if directory already exists" do
      dir_asset2 = DirectoryAsset.new('directory_name' => @test_dir, 'parent_id' => nil, 'version' => current_version)
      dir_asset2.save
      dir_asset2.success.should == false
      dir_asset2.errors.full_messages.should == [error_message(1)]
    end

    it "should not create a directory if version mismatch occurs" do
      dir_asset = DirectoryAsset.new('directory_name' => 'testdir', 'parent_id' => nil, 'version' => (current_version + 1))
      dir_asset.save
      dir_asset.success.should == false
      dir_asset.errors.full_messages.should == [error_message(0)]
    end

  end

end
