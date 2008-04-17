class Admin::FileController < ApplicationController
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
  end
  
  def new
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    if request.post? && (upload = params[:asset][:uploaded_data])
      upload_location = FileBrowserExtension.asset_path
      new_file = File.join(upload_location, upload.original_filename)
      File.open(new_file, 'wb') { |f| f.write(upload.read) }
      redirect_to files_path
    end
  end
end