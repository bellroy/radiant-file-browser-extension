class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
  end
  
  def new
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @parent_id = params[:parent_id]
    if request.post? 
      new_type = params[:new_type]
      if @parent_id == '' or @parent_id.nil?
        upload_location = FileBrowserExtension.asset_path        
      else
        upload_location = id2path(@parent_id)        
      end
   
      if new_type == 'UPLOAD' && (upload = params[:asset][:uploaded_data])
        new_file = File.join(upload_location, upload.original_filename)
        File.open(new_file, 'wb') { |f| f.write(upload.read) }
        redirect_to files_path      
      elsif new_type == 'CREATE'
        directory_name = params[:asset][:directory_name]
        new_dir = File.join(upload_location, directory_name)        
        directory_path = Pathname.new(new_dir)
        Dir.mkdir(directory_path) unless directory_path.directory?
        redirect_to files_path 
      end      
    end
  end
  
  def children
    @id = params[:id]
    @assets = Pathname.new(FileBrowserExtension.asset_path)   
    @indent_level = params[:indent_level]
    @asset_list = params[:asset_list]
    render :layout => false
  end
  
  def remove
    id = params[:id].to_i
    asset_absolute_path = Pathname.new(FileBrowserExtension.asset_path)
    asset_array = get_directory_array(asset_absolute_path)
    @file = Pathname.new(asset_absolute_path + asset_array[id])
    if request.post?
      
    end
  end
end