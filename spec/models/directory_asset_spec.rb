require File.dirname(__FILE__) + '/../spec_helper'

describe DirectoryAsset do

  before do
    @test_dir = 'Test1' 
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)

    @dir_asset = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
    @dir_status = @dir_asset.save
  end

  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  it "should get absolute root path" do
    DirectoryAsset.absolute_path.should == absolute_path
  end

  describe "Directory Creation" do

    it "should create a directory" do
      @dir_status.should_not == nil
      Pathname.new(absolute_path(@test_dir)).directory?.should == true      
    end 

    it "should create a directory within another directory" do
      parent_id = @dir_asset.id
      dir_asset2 = DirectoryAsset.new('name' => 'ChildDir', 'parent_id' => parent_id, 'version' => current_version, 'new_type' => 'Directory') 
      dir_asset2.save.should_not == nil
      Pathname.new(absolute_path(File.join(@test_dir, 'ChildDir'))).directory?.should == true      
    end

    it "should not create a directory if it contains a leading period" do
      dir_asset = DirectoryAsset.new('name' => '.AbcPqr', 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
      dir_asset.save.should == nil
      dir_asset.errors.full_messages.should == [error_message(:illegal_name)]
    end

    fixture = [
      #consists                 assetname           sanitized
      ['^ and &',              'Abc^Pqr&Xyz',     'Abc_Pqr_Xyz'],
      ['/',                    'Abc/Pqr',         'Abc_Pqr'],  
      ['\\',                   'Abc/Pqr\\Xyz',    'Abc_Pqr_Xyz'],
    ]

    fixture.each do |consists, name, sanitized_name|
      it "should sanitize directory names when it contains special chars (consists #{consists})" do
        dir_asset = DirectoryAsset.new('name' => name, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
        dir_asset.save
        id = dir_asset.id
        id2path(id).basename.to_s.should == sanitized_name
      end
    end
   
    it "should not create a directory if directory already exists" do
      dir_asset2 = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
      dir_asset2.save.should == nil
      dir_asset2.errors.full_messages.should == [error_message(:exists)]
    end

    it "should not create a directory if version mismatch occurs" do
      dir_asset = DirectoryAsset.new('name' => 'testdir', 'parent_id' => nil, 'version' => (current_version + 1), 'new_type' => 'Directory')
      dir_asset.save.should == nil
      dir_asset.errors.full_messages.should == [error_message(:modified)]
    end

  end

end
