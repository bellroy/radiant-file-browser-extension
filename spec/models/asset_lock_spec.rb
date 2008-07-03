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

  it "should return true if version matches" do
    lock_version = AssetLock.lock_version

    AssetLock.confirm_lock(lock_version).should == true
  end

  it "should return false if version does not match" do
    lock_version = AssetLock.lock_version

    AssetLock.new_lock_version
    AssetLock.confirm_lock(lock_version).should == false
  end

  it "should return false if version if not sent for confirm" do
    AssetLock.confirm_lock(nil).should == false
    AssetLock.confirm_lock('').should == false
  end

end
