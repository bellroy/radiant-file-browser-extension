require File.dirname(__FILE__) + '/../spec_helper'

describe Asset do

  before do
    @test_dir = 'Test1' 
    @renamed_test_dir = 'Test1_new'
    @second_test_dir = 'Test2'

    @test_upload_file = 'test_image.jpg'
    @renamed_test_upload_file = 'test_image_new.jpg'
    @second_test_upload_file = 'test_image2.jpg'

    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    @dir = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
    @dir.save

    @file = FileAsset.new('uploaded_data' => fixture_file_upload(@test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => current_version, 'new_type' => 'File')
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
      asset.errors.full_messages.should == [error_message(:modified)]
    end
    
    it "should find a file if id and version matches" do
      Asset.find(@file.id, current_version).pathname.should == Pathname.new(absolute_path(@test_upload_file))
    end
    
    it "should not find a file if version does not match and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, (current_version + 1))
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:modified)]
    end

    it "should not find a directory if version parameter is not sent and provide an asset error with error no. 0" do
      asset = Asset.find(@dir.id, nil)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:modified)]

      asset = Asset.find(@dir.id, '')
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:modified)]
    end

    it "should not find a file if version parameter is not sent and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, nil)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:modified)]

      asset = Asset.find(@file.id, '')
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:modified)]
    end

    it "should provide asset error with error no. 3 if id parameter is not sent" do
      asset = Asset.find(nil, current_version)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:blankid)]

      asset = Asset.find(' ', current_version)
      asset.pathname.should == nil
      asset.errors.full_messages.should == [error_message(:blankid)]
    end

  end


  describe "edit" do

    it "should edit the name of a directory" do
      asset = Asset.find(@dir.id, current_version)
      asset.rename('name' => @renamed_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_dir))  
    end

    it "should edit the name of a file" do
      asset = Asset.find(@file.id, current_version)
      asset.rename('name' => @renamed_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@renamed_test_upload_file))  
    end

    it "should not edit the name of a directory if directory name already exists and provide an asset error with error no. 1" do
      DirectoryAsset.new('name' => @second_test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory').save
      asset = Asset.find(@dir.id, current_version)
      asset.rename('name' => @second_test_dir, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_dir))
      Pathname.new(absolute_path(@test_dir)).directory?.should == true
      asset.errors.full_messages.should == [error_message(:exists)]
    end

    it "should not edit the name of a file if file name already exists and provide an asset error with error no. 1" do
      FileAsset.new('uploaded_data' => fixture_file_upload(@second_test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => current_version, 'new_type' => 'File').save
      asset = Asset.find(@file.id, current_version)
      asset.rename('name' => @second_test_upload_file, 'version' => current_version)
      asset.pathname.should == Pathname.new(absolute_path(@test_upload_file))
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should == [error_message(:exists)]
    end

    it "should not edit directory if directory name consists of a leading period" do
        asset = Asset.find(@dir.id, current_version)
        asset.rename('name' => '.testfile', 'version' => current_version)
        asset.pathname.should == Pathname.new(absolute_path(@test_dir))
        Pathname.new(absolute_path(@test_dir)).directory?.should == true
        asset.errors.full_messages.should == [error_message(:illegal_name)]
    end

    fixture = [
        #consists                 assetname          sanitized 
        ['^ and "',             'test^fi"le',      'test_fi_le'],
        ['/',                    'test/file',        'test_file'],  
        ['\\',                   'test\\file',       'test_file'],
    ]
    fixture.each do |consists, name, sanitized|
      it "should sanitize directory name if it contains special characters" do
        asset = Asset.find(@dir.id, current_version)
        asset.rename('name' => name, 'version' => current_version)
        asset.pathname.should == Pathname.new(absolute_path(sanitized))
        Pathname.new(absolute_path(sanitized)).directory?.should == true
      end

      it "should sanitize file name if it contains special characters" do
       asset = Asset.find(@file.id, current_version)
       asset.rename('name' => name, 'version' => current_version)
       asset.pathname.should == Pathname.new(absolute_path(sanitized))
       Pathname.new(absolute_path(sanitized)).file?.should == true
      end
    end

    it "should not edit a directory if version mismatch occurs and provide an asset error with error no. 0" do
      asset = Asset.find(@dir.id, (current_version + 1))
      asset.rename('name' => @second_test_dir)
      Pathname.new(absolute_path(@test_dir)).directory?.should == true
      asset.errors.full_messages.should include(error_message(:unknown))
    end

    it "should not edit a file if version mismatch occurs and provide an asset error with error no. 0" do
      asset = Asset.find(@file.id, (current_version + 1))
      asset.rename('name' => @second_test_upload_file)
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should include(error_message(:unknown))
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
      asset.errors.full_messages.should include(error_message(:modified))
    end
    
    it "should not remove a file if version mismatch occurs" do
      asset = Asset.find(@file.id, current_version + 1)
      asset.destroy.should == false
      Pathname.new(absolute_path(@test_upload_file)).file?.should == true
      asset.errors.full_messages.should include(error_message(:modified))
    end

  end
  

  describe "protected methods" do

    it "should get the absolute root path" 

    it "should get the absolute upload location for a parent" 

    it "should confirm the validity of the asset name" 

    it "should sanitize asset name by converting all special chars except ., / and \\ into an underscore" 

  end

end
