require File.dirname(__FILE__) + '/../../../spec_helper'

def current_version
  AssetLock.lock_version
end

describe "/admin/file/children.rhtml" do

    before(:each) do
      @test_dir = 'Test1' 
      FileUtils.mkdir_p(FileBrowserExtension.asset_path)

      @dir_asset = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory') 
      @dir_asset.save
    end

    after do
      FileUtils.rm_r(FileBrowserExtension.asset_path)
    end

    it "should render children" do
        assigns[:id] = @dir_asset.id
        assigns[:assets] = @dir_asset.pathname
        assigns[:indent_level] = 0
        assigns[:asset_lock] = current_version

        render "/admin/file/children.rhtml"
        response.should be_success
    end

end
