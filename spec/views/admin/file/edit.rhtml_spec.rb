require File.dirname(__FILE__) + '/../../../spec_helper'

describe "/admin/file/edit.rhtml" do

  before(:each) do
    @test_upload_file = 'test_image.jpg'
    FileUtils.mkdir_p(FileBrowserExtension.asset_path)
    @file = FileAsset.new('uploaded_data' => fixture_file_upload(@test_upload_file, "image/jpg"), 'parent_id' => nil, 'version' => AssetLock.lock_version, 'new_type' => 'File')
    @file.save
 
    assigns[:file] = @file
  end
  after do
    FileUtils.rm_r(FileBrowserExtension.asset_path)
  end

  it "should render edit asset page" do
    render "/admin/file/edit.rhtml"

    response.should be_success
    response.should have_tag("form[action=''][method=post]") do
      with_tag("input[type='text'][name='asset[name]'][value=#{@file.pathname.basename}]")
    end
  end

end
