require File.dirname(__FILE__) + '/../../../spec_helper'

describe "/admin/file/children.rhtml" do

    before(:each) do
        @test_dir_path = File.join(FileBrowserExtension.asset_path, 'Test1')
    end

    it "should render children" do
        Dir.mkdir(@test_dir_path)      
	@id = path2id(@test_dir_path) 
        @assets = Pathname.new(FileBrowserExtension.asset_path)   
        assigns[:id] = @id
        assigns[:assets] = @assets
        assigns[:ident_level] = 0

        render "/admin/file/children.rhtml"
        Pathname.new(@test_dir_path).rmdir

        response.should be_success
    end

end
