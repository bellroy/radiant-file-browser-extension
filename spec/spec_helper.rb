unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  case
  when ENV["RADIANT_ENV_FILE"]
    require ENV["RADIANT_ENV_FILE"]
  when File.dirname(__FILE__) =~ %r{vendor/radiant/vendor/extensions}
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../../../")}/config/environment"
  else
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
  end
end
require "#{RADIANT_ROOT}/spec/spec_helper"
 
if File.directory?(File.dirname(__FILE__) + "/scenarios")
  Scenario.load_paths.unshift File.dirname(__FILE__) + "/scenarios"
end
if File.directory?(File.dirname(__FILE__) + "/matchers")
  Dir[File.dirname(__FILE__) + "/matchers/*.rb"].each {|file| require file }
end
 
include ApplicationHelper
include DirectoryArray
 
Spec::Runner.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures = false
  config.fixture_path = RAILS_ROOT + '/vendor/extensions/file_browser/spec/fixtures/'
 
  # You can declare fixtures for each behaviour like this:
  # describe "...." do
  # fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end
 
  
def time_taken_to
  t = Time.now
  yield
  Time.now - t
end
 
def create_lots_of_files
  10.times do |i|
    Dir.mkdir(File.join(FileBrowserExtension.asset_path,i.to_s))
    10.times do |j|
      Dir.mkdir(File.join(FileBrowserExtension.asset_path, i.to_s, j.to_s))
      10.times do |k|
        FileUtils.touch(File.join(FileBrowserExtension.asset_path, i.to_s, j.to_s, k.to_s))
      end
    end
  end
end
 
def delete_those_lots_of_files
  10.times {|i| FileUtils.rm_rf(File.join(FileBrowserExtension.asset_path,i.to_s))}
end
