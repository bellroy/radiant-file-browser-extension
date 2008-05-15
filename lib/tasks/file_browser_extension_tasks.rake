namespace :radiant do
  namespace :extensions do
    namespace :file_browser do
      
      desc "Runs the migration of the File Browser extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          FileBrowserExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          FileBrowserExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the File Browser to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[FileBrowserExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(FileBrowserExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
