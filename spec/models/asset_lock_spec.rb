require File.dirname(__FILE__) + '/../spec_helper'

describe AssetLock do
  it "should initially have a lock_version of 0" do
    AssetLock.lock_version.should equal(0)
  end

  it "should not change lock_version when asked multiple times" do
    lock_version = AssetLock.lock_version

    AssetLock.lock_version.should == lock_version
  end

  it "should give a new_lock_version" do
    lock_version = AssetLock.lock_version

    AssetLock.new_lock_version.should > lock_version
  end
end
