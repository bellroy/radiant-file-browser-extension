# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

require 'pathname'

class FileBrowserExtension < Radiant::Extension
  version "0.1"
  description "Simple Extension to list the contents of a server-side directory inside Radiant and upload files to it."
  url "http://trike.com.au"
  
  define_routes do |map|
    # map.connect 'admin/store/:action', :controller => 'store'
    # Product Routes
    map.with_options(:controller => 'admin/file') do |admin|
      admin.files     'admin/files',                 :action => 'index'
      admin.new_file  'admin/files/new',             :action => 'new'
      admin.child_files  'admin/files/children',     :action => 'children'
      admin.edit_files   'admin/files/edit',         :action => 'edit'
      admin.remove_file  'admin/files/remove',       :action => 'remove'      
    end
    
  end

  def activate
    admin.tabs.add "Assets", "/admin/files", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    admin.tabs.remove "Assets"
  end
  
  def self.asset_parent_path
    File.join "#{RAILS_ROOT}", 'public'
  end
  
  # Returns the absolute filesystem path to the asset directory as a string
  def self.asset_path
    
    if ENV["RAILS_ENV"] == 'test'
       File.join asset_parent_path, 'assets_test'
    else
       File.join asset_parent_path, 'assets_test'
    end
  end
  
end
