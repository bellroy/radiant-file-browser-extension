require File.dirname(__FILE__) + '/../../../spec_helper'

describe "/admin/file/edit.rhtml" do

    before(:each) do
        @asset_lock = AssetLock.lock_version
        assigns[:asset_lock] = @asset_lock
    end

    it "should render edit asset page" do
        file_name = "JustAFileName.txt"
        assigns[:file_name] = file_name
        render "/admin/file/edit.rhtml"

        response.should be_success
        response.should have_tag("form[action=''][method=post]") do
             with_tag("input[type='hidden'][name='version'][value=#{@asset_lock}]")
             with_tag("input[type='text'][name='file_name'][value=#{file_name}]")
        end
    end

end
