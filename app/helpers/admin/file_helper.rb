module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray
  
  def print_path(path, indent_level=0)
    output = ''    
    asset_array = get_directory_array(@asset_absolute_path)
    relative_path = path.relative_path_from(@asset_absolute_path)
    file_id = asset_array.index(relative_path)
    if path.directory?
      output << print_dir_node(path, indent_level, file_id)
      # output << print_children(path, indent_level)
    else
      output << print_file_node(path, indent_level, file_id)
    end
    output
  end
  
  def render_children(path, id='', indent_level=0)
    if path.directory?
      @asset_absolute_path = path    
      asset_array = get_directory_array(path)
      if id != ''
        path = path + asset_array[id.to_i].to_s
        path = Pathname.new(path)
      end
      print_children(path, indent_level.to_i)
    else
      print_file_node(path) 
    end
  end
  
  def print_children(path, indent_level=0)       
    path.children.collect do |child|
      print_path(child, indent_level+1) unless hidden?(child)
    end.to_s
  end
  
  def asset_json(path)
    asset_array = get_directory_array(path)
    asset_array.to_json
  end
  
  private
    def print_dir_node(file, indent_level=0, file_id=0)
      html_class = "node level-#{indent_level} children-hidden"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}" >
        <td class="directory" style="padding-left: #{padding_left(indent_level)}px">
          <span class="w1">
          #{expander}         
          #{icon_for(file)}
          <span class="title">#{file.basename.to_s}</span>
          #{spinner(file_id)}          
          </span>
        </td>
        <td class="type">Folder</td>
        <td class="size"></td>
        <td class="embed"></td>
        <td class="add-child">#{link_to_new_file(file_id)}</td>
        <td class="remove">#{link_to_remove_file(file_id)}</td> 
      </tr>}
    end
    
    def print_file_node(file, indent_level=0, file_id=0)
      html_class = "node level-#{indent_level} no-children"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}">
        <td class="file" style="padding-left: #{padding_left(indent_level)}px">
          #{icon_for(file)}
          <span class="title">#{file.basename.to_s}</span>
        </td>
        <td class="type">#{type_description_for(file)}</td>
        <td class="size">#{number_to_human_size(file.size)}</td>
        <td class="embed">#{link_or_embed_field_for(file)}</td>
        <td class="add-child"></td>
        <td class="remove">#{link_to_remove_file(file_id)}</td>        
      </tr>}
    end
            
    def icon_for(path)
      image_tag 'admin/page.png', :alt => '', :class => 'icon'
    end

    def type_description_for(path)
      ext(path).upcase + (image?(path) ? ' Image' : ' File')
    end
    
    def ext(path)
      path.extname.gsub('.','')
    end
    
    Image_extensions = %w[png gif jpg jpeg]
    def image?(path)
      Image_extensions.include?(ext(path))
    end
        
    def link_or_embed_field_for(path)
      template_code = (image?(path) ? embed_code_for(path) : link_code_for(path))
      %Q{
        <input type="text" value="#{h(template_code)}"
         style="width: 100%"
         onclick="this.focus();this.select()" />
      }
    end
    
    def embed_code_for(path)
      %Q{<r:img src="#{http_path(path)}" />}
    end
    
    def link_code_for(path)
      %Q{<r:asset_link href="#{http_path(path)}">#{path.basename} (#{type_description_for(path)}, #{number_to_human_size(path.size)})</r:asset_link>}
    end
    
    # Returns the HTTP-Accessible path for the given absolute filesystem path
    def http_path(path)
      http_root = Pathname.new(FileBrowserExtension.asset_path)
      path.relative_path_from(http_root)
    end
      
    def add_children_button_for(path)
      link_to(image_tag('admin/add-child.png', :alt => 'Add Child'), new_file_path)
    end
    
    # def remove_button_for(path)
    #   link_to(image_tag('admin/remove.png', :alt => 'Remove File'), remove_file_path(:path => path.to_s))
    # end    
    
    #added by Sanath
    def expander
      image("expand", 
            :class => "expander", :alt => 'toggle children', 
            :title => '')      
    end    
    
    def spinner(file_id)
      image('spinner.gif', 
              :class => 'busy', :id => "busy-#{file_id}", 
              :alt => "",  :title => "", 
              :style => 'display: none;')
    end    
      
    def link_to_new_file(file_id)
      link_to image('add-child', :alt => 'add child'), new_file_path(:parent_id => file_id)
    end
  
    def link_to_remove_file(file_id)
      link_to image('remove', :alt => 'remove page'), '/admin/files/remove?id=' + file_id.to_s
    end
  
end