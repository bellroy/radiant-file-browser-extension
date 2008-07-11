require File.dirname(__FILE__) + '/../../../spec_helper'

def current_version
  AssetLock.lock_version
end

describe "/admin/file/remove.rhtml" do

    before(:each) do
      @test_dir = 'Test1' 
      FileUtils.mkdir_p(FileBrowserExtension.asset_path)

      @dir_asset = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
      @dir_asset.save

      assigns[:id] = @dir_asset.id
      assigns[:asset] = @dir_asset
      assigns[:asset_lock] = current_version
      assigns[:v] = current_version
    end
    after do
      FileUtils.rm_r(FileBrowserExtension.asset_path)
    end

    it "should render remove asset page" do 

      render "/admin/file/remove.rhtml"

      response.should be_success
      response.should have_tag("form[action=''][method=post]") do
        # with_tag("input[type='hidden'][name='version'][value=#{current_version}]")
      end
  
    end

end
