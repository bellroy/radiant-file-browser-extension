require File.dirname(__FILE__) + '/../../../spec_helper'

describe "/admin/file/remove.rhtml" do

    before(:each) do
        @asset_lock = AssetLock.lock_version
        @test_dir_path = File.join(FileBrowserExtension.asset_path, 'Test1')
        assigns[:asset_lock] = @asset_lock
    end

    it "should render remove asset page" do 
        Dir.mkdir(@test_dir_path) 
        assigns[:path] = Pathname.new(@test_dir_path)

        render "/admin/file/remove.rhtml"
        Pathname.new(@test_dir_path).rmdir

        response.should be_success
        response.should have_tag("form[action=''][method=post]") do
             with_tag("input[type='hidden'][name='version'][value=#{@asset_lock}]")
        end
    
    end

end