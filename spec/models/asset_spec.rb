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

    it "should find asset if id and version matches(directory)" do
      Asset.find(@dir.id, current_version).pathname.should == Pathname.new(absolute_path(@test_dir))
    end

    it "should not find the asset if version does not match and provide an error no. 0(directory)" do
      asset = Asset.find(@dir.id, (current_version + 1))
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end
    
    it "should find asset if id and version matches(file)" do
      Asset.find(@file.id, current_version).pathname.should == Pathname.new(absolute_path(@test_upload_file))
    end
    
    it "should not find the asset if version does not match and provide an error no. 0(file)" do
      asset = Asset.find(@file.id, (current_version + 1))
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should provide error no. 3 if no. id is not sent" do
      asset = Asset.find(nil, current_version)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(3)]
    end

  end

#########

  describe "edit" do

    it "should edit the name of the asset(directory)" do
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @renamed_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_dir))  
    end

    it "should edit the name of the asset(file)" do
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @renamed_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_upload_file))  
    end

    it "should not edit the name of the asset if asset name already exists and give error no. 1 (directory)" do
      DirectoryAsset.new('directory_name' => @second_test_dir, 'parent_id' => nil, 'version' => current_version).save
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @second_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_dir))
      asset.errors.full_messages.should == [error_message(1)]
    end

    it "should not edit the name of the asset if asset name already exists and give error no. 1 (file)" do
      FileAsset.new('uploaded_data' => fixture_file_upload(@second_test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => current_version).save
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @second_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
      asset.errors.full_messages.should == [error_message(1)]
    end

    fixture = [
        #consists      assetname
        ['.',         '.testfile'],
        ['/',         'test/file'],  
        ['\\',        'test\\file'],
      ]
      fixture.each do |consists, name|
        it "should not edit if filename consists of #{consists} and give error no. 2 (directory)" do
          asset = Asset.find(@dir.id, current_version)
          asset.update('name' => name, 'version' => current_version)
          asset.pathname.should == Pathname.new(absolute_path(@test_dir))
          asset.errors.full_messages.should == [error_message(2)]
        end

        it "should not edit if filename consists of #{consists} and give error no. 2 (file) " do
         asset = Asset.find(@file.id, current_version)
         asset.update('name' => name + '.jpg', 'version' => current_version)
         asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
         asset.errors.full_messages.should == [error_message(2)]
        end
     end

    it "should not edit if version mismatch occurs and give error no. 0 (directory)" do
      asset = Asset.find(@dir.id, current_version)
      asset.update('name' => @second_test_dir, 'version' => (current_version + 1))
      asset.pathname.should == Pathname.new(absolute_path(@test_dir))
      asset.errors.full_messages.should == [error_message(0)]
    end

    it "should not edit if version mismatch occurs and give error no. 0 (file)" do
      asset = Asset.find(@file.id, current_version)
      asset.update('name' => @second_test_upload_file, 'version' => (current_version + 1))
      asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
      asset.errors.full_messages.should == [error_message(0)]
    end

  end

#########
  describe "destroy" do

    it "should remove an asset (directory)" do
      asset = Asset.find(@dir.id, current_version)
      asset.destroy.should == true
    end

    it "should remove an asset (file)" do
      asset = Asset.find(@file.id, current_version)
      asset.destroy.should == true
    end

    it "should not remove an asset if version mismatch occurs  (directory)" do
      asset = Asset.find(@dir.id, current_version + 1)
      asset.destroy.should == false
      asset.errors.full_messages.should == [error_message(0)]
    end
    
    it "should not remove an asset if version mismatch occurs  (file)" do
      asset = Asset.find(@file.id, current_version + 1)
      asset.destroy.should == false
      asset.errors.full_messages.should == [error_message(0)]
    end

  end
  
#########
  decribe "protected methods" do

    it "should get the absolute root path" do
      DirectoryAsset.get_absolute_path.should == FileBrowserExtension.asset_path
    end

    it "should get the absolute upload location for a parent" do
      upload_location = DirectoryAsset.get_upload_location(@dir.id)
      upload_location.should == id2path(@dir.id)  
    end

    it "should confirm the validity of the asset name" do
      asset_name = '.TT'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false

      asset_name = 'TT/NN'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false

      asset_name = 'TT\\NN'
      DirectoryAsset.confirm_asset_validity_and_sanitize(asset_name).should == false
    end

  end

end
