module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray

  def render_children(asset, locals = {})
    @current_asset = asset
    locals.reverse_merge!(:level => 0, :simple => false, :show_parent => false, :asset_lock => AssetLock.lock_version).merge!(:asset => asset)
    render :partial => 'children', :locals =>  locals
  end  
  
  def html_class
    @current_asset.children.empty? ? "children-hidden" : "no-children"
  end
              
  def icon_for(class_type)
    class_type == "directory" ? image_name = "page.png" : image_name = "snippet.png"
    image_tag "admin/#{image_name}", :alt => '', :class => 'icon'
  end
        
  def link_or_embed_field_for(asset)
    template_code = asset.embed_tag
    %Q{
      <input type="text" value="#{h(template_code)}"
       style="width: 100%"
       onclick="this.focus();this.select()" />
     }
  end    
        
  def expander(expanded)
    return nil if @current_asset.children.empty?
    image(expanded ? "collapse" : "expand", 
          :class => "expander", :alt => 'toggle children', 
          :title => '')     
  end    
    
  def spinner(file_id)
    image('spinner.gif', 
            :class => 'busy', :id => "busy-#{file_id}", 
            :alt => "",  :title => "", 
            :style => 'display: none;')
  end    
      
  def link_to_new_file(file_id, asset_lock)
    link_to image('add-child', :alt => 'add child'), new_file_path(:parent_id => file_id, :v => asset_lock)
  end
  
  def link_to_remove_file(file_id, asset_lock)
    link_to image('remove', :alt => 'remove page'), '/admin/files/remove?id=' + file_id.to_s + '&v=' + asset_lock.to_s
  end
  
end
