require File.dirname(__FILE__) + '/../spec_helper'

def current_version
  AssetLock.lock_version
end

def error_message(error_no)
  Asset::Errors::CLIENT_ERRORS[error_no]
end

describe Asset do

  before do
    @test_dir = 'Test1' 
    @renamed_test_dir = 'Test1_new'
    @second_test_dir = 'Test2'

    @test_upload_file = 'test_image.jpg'
    @renamed_test_upload_file = 'test_image_new.jpg'
    @second_test_upload_file = 'test_image2.jpg'

    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    @dir = DirectoryAsset.new('directory_name' => @test_dir, 'parent_id' => nil, 'version' => current_version)
    @dir.save

    @file = FileAsset.new('uploaded_data' => fixture_file_upload(@test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => current_version)
    @file.save
  end

  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  describe "find" do

    it "should find a directory if id and version matches" do
      Asset.find(@dir.id, current_version).pathname.should == Pathname.new(absolute_path(@test_dir))
    end

    it "should not find a directory if version does not match and provide an asset error with error no. 0" do
      asset = Asset.find(@dir.id, (current_version + 1))
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end
    
    it "should find a file if id and version matches" do
      Asset.find(@file.id, current_version).pathname.should == Pathname.new(absolute_path(@test_upload_file))
    end
    
    it "should not find a file if version does not match and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, (current_version + 1))
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should not find a directory if version parameter is not sent and provide an asset error with error no. 0" do
      asset = Asset.find(@dir.id, nil)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]

      asset = Asset.find(@dir.id, '')
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should not find a file if version parameter is not sent and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, nil)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]

      asset = Asset.find(@file.id, '')
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should provide asset error with error no. 3 if id parameter is not sent" do
      asset = Asset.find(nil, current_version)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(3)]

      asset = Asset.find(' ', current_version)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(3)]
    end

  end


  describe "edit" do

    it "should edit the name of a directory" do
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @renamed_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_dir))  
    end

    it "should edit the name of a file" do
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @renamed_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_upload_file))  
    end

    it "should not edit the name of a directory if directory name already exists and provide an asset error with error no. 1" do
      DirectoryAsset.new('directory_name' => @second_test_dir, 'parent_id' => nil, 'version' => current_version).save
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @second_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_dir))
      Pathname.new(absolute_path(@test_dir)).directory?.should == true
      asset.errors.full_messages.should == [error_message(1)]
    end

    it "should not edit the name of a file if file name already exists and provide an asset error with error no. 1" do
      FileAsset.new('uploaded_data' => fixture_file_upload(@second_test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => current_version).save
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @second_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should == [error_message(1)]
    end

    fixture = [
        #consists                 assetname
        ['leading period',       '.testfile'],
        ['/',                    'test/file'],  
        ['\\',                   'test\\file'],
    ]
    fixture.each do |consists, name|
      it "should not edit a directory if directory name consists of #{consists} and provide an asset error with error no. 2" do
        asset = Asset.find(@dir.id, current_version)
        asset.update('name' => name, 'version' => current_version)
        asset.pathname.should == Pathname.new(absolute_path(@test_dir))
        Pathname.new(absolute_path(@test_dir)).directory?.should == true
        asset.errors.full_messages.should == [error_message(2)]
      end

      it "should not edit a file if filename consists of #{consists} and provide an asset error with error no. 2" do
       asset = Asset.find(@file.id, current_version)
       asset.update('name' => name + '.jpg', 'version' => current_version)
       asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
       Pathname.new(absolute_path(@test_upload_file)).file?.should == true
       asset.errors.full_messages.should == [error_message(2)]
      end
    end

    it "should not edit a directory if version mismatch occurs and provide an asset error with error no. 0" do
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @second_test_dir, 'version' => (current_version + 1))
      asset.pathname.should == Pathname.new(absolute_path(@test_dir))
      Pathname.new(absolute_path(@test_dir)).directory?.should == true
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should not edit a file if version mismatch occurs and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @second_test_upload_file, 'version' => (current_version + 1))
      asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should == [error_message(0)]
    end

  end


  describe "destroy" do

    it "should remove a directory" do
      asset = Asset.find(@dir.id, current_version)
      asset.destroy.should == true
      Pathname.new(absolute_path(@test_dir)).directory?.should == false
    end

    it "should remove a file" do
      asset = Asset.find(@file.id, current_version)
      asset.destroy.should == true
      Pathname.new(absolute_path(@test_upload_file)).file?.should == false
    end

    it "should not remove a directory if version mismatch occurs" do
      asset = Asset.find(@dir.id, current_version + 1)
      asset.destroy.should == false
      Pathname.new(absolute_path(@test_dir)).directory?.should == true
      asset.errors.full_messages.should == [error_message(0)]
    end
    
    it "should not remove a file if version mismatch occurs" do
      asset = Asset.find(@file.id, current_version + 1)
      asset.destroy.should == false
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should == [error_message(0)]
    end

  end
  

  describe "protected methods" do

    it "should get the absolute root path" do
      DirectoryAsset.get_absolute_path.should == FileBrowserExtension.asset_path
    end

    it "should get the absolute upload location for a parent" do
      upload_location = DirectoryAsset.get_upload_location(@dir.id)
      upload_location.should == id2path(@dir.id)  

      upload_location = DirectoryAsset.get_upload_location(nil)
      upload_location.should == FileBrowserExtension.asset_path
    end

    it "should confirm the validity of the asset name" do
      asset_name = '.TT'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false

      asset_name = 'TT/NN'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false

      asset_name = 'TT\\NN'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false
    end

    it "should sanitize asset name by converting all special chars except ., / and \\ into an underscore" do
      asset_name = 'TT$NN^B*A`~\'"Y'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == 'TT_NN_B_A____Y'
    end

  end

end
