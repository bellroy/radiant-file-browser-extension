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
    end
    
  end

  def activate
    admin.tabs.add "Assets", "/admin/files", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    admin.tabs.remove "Assets"
  end
  
  # Returns the absolute filesystem path to the asset directory as a string
  def self.asset_path
    File.expand_path('public/assets')
  end
  
end