require File.dirname(__FILE__) + '/../../../spec_helper'

describe "/admin/file/index.rhtml" do
  before(:each) do
    assigns[:root_asset] = Asset.root
    template.stub! :form_authenticity_token
  end
  
  def render_index
    render "/admin/file/index.rhtml"
  end

  MAX_EMPTY_RENDER_TIME = 0.1
  it "should render empty directory in less than #{MAX_EMPTY_RENDER_TIME} seconds" do
    time_taken_to{ render_index }.should <= MAX_EMPTY_RENDER_TIME
  end

  # The first level nodes start collapsed, so it shouldn't take long
  MAX_RENDER_TIME = 1.0
  it "should render populated directory in less than #{MAX_RENDER_TIME} seconds" do    
    begin
      create_lots_of_files
      time_taken_to{ render_index }.should <= MAX_RENDER_TIME
    ensure
      delete_those_lots_of_files
    end
  end
end
