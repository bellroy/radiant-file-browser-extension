require File.dirname(__FILE__) + '/../../../spec_helper'

def current_version
  AssetLock.lock_version
end

describe "/admin/file/new.rhtml" do

  before(:each) do
    @asset_lock = AssetLock.lock_version
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    assigns[:asset_lock] = @asset_lock
  end

  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  it "should render new asset page" do
    render "/admin/file/new.rhtml"

    response.should have_tag("form[action=''][method=post]")    
  end    

  it "should render add child page" do
    @test_dir = 'Test1' 
    @dir_asset = DirectoryAsset.new('name' => @test_dir, 'parent_id' => nil, 'version' => current_version, 'new_type' => 'Directory')
    @dir_asset.save
    assigns[:parent_id] = @dir_asset.id
    render "/admin/file/new.rhtml"        

    response.should have_tag("form[action=''][method=post]") do
      with_tag("input[type='hidden'][name='asset[version]'][value=#{@asset_lock}]")
      with_tag("input[type='hidden'][name='asset[parent_id]'][value=#{@dir_asset.id}]")
    end  
  end    

end
