require File.dirname(__FILE__) + '/../spec_helper'

describe AssetLock do
  before(:each) do
    @asset_lock = AssetLock.new
  end

  it "should be valid" do
    @asset_lock.should be_valid
  end
end
