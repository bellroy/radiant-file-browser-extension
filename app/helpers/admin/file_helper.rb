module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray

      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        if object = options.delete(:object)
          objects = [object].flatten
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first
          options[:header_message] = "Following errors prohibited this #{options[:object_name].to_s.gsub('_', ' ')} from being saved" unless options.include?(:header_message)
          options[:message] ||= 'There were problems with the following fields:' unless options.include?(:message)
          error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }

          contents = ''
          contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
          contents << content_tag(:p, options[:message]) unless options[:message].blank?
          contents << content_tag(:ul, error_messages)

          content_tag(:div, contents, html)
        else
          ''
        end
      end  

  def print_path(path, indent_level=0, simple=false, asset_lock=nil)
    output = ''    
    if path.directory?
      output << print_dir_node(path, indent_level, false, simple, asset_lock)
    else
      output << print_file_node(path, indent_level, simple, asset_lock)
    end
    output
  end
  
  def render_children(path, id='', indent_level=0, show_parent_dir=false, simple=false, asset_lock=nil)
    if path.directory?
      @asset_absolute_path = path    
      asset_array = get_directory_array(path)
      if id != ''
        path = path + asset_array[id.to_i].to_s
        path = Pathname.new(path)
      end
      print_children(path, indent_level.to_i, show_parent_dir, simple, asset_lock)
    else
      print_file_node(path, 0, simple, asset_lock) 
    end
  end
  
  def print_children(path, indent_level=0, show_parent_dir=false, simple=false, asset_lock=nil)  
    output = ''    
    output << print_dir_node(path, 0, true, simple, asset_lock) if show_parent_dir == true 
    path.children.collect do |child|
      output << print_path(child, indent_level+1, simple, asset_lock) unless hidden?(child)
    end
    output
  end
  
  def asset_to_array(path)
    asset_array = get_directory_array(path)
    output = '['
    asset_array.each do |a|
      output << '"' + a + '"'
      output << ","      
    end
    output.chomp!(',')
    output << ']'
  end
  
  private
    def print_dir_node(file, indent_level=0, dont_expand=false, simple=false, asset_lock=nil)
      file_id = path2id(file)
      html_class = "node level-#{indent_level} children-hidden"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}" >
        <td class="directory" style="padding-left: #{padding_left(indent_level)}px">
          <span class="w1">
          #{expander dont_expand}         
          #{icon_for(file)}
          <span class="title"><a href='/admin/files/edit?id=#{file_id}&v=#{asset_lock}'>#{file.basename.to_s}</a></span>
          #{spinner(file_id)}          
          </span>
        </td>
        <td class="type">Folder</td>
       } + 
        if !simple 
          %Q{ 
          <td class="size"></td>
          <td class="embed"></td>
          <td class="add-child">#{link_to_new_file(file_id, asset_lock)}</td>
          <td class="remove">#{link_to_remove_file(file_id, asset_lock)}</td> 
          </tr>} 
        else
          ''
        end
    end
    
    def print_file_node(file, indent_level=0, simple=false, asset_lock=nil)
      file_id = path2id(file)      
      html_class = "node level-#{indent_level} no-children"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}">
        <td class="file" style="padding-left: #{padding_left(indent_level)}px">
          #{icon_for(file)}
          <span class="title"><a href='/admin/files/edit?id=#{file_id}&v=#{asset_lock}'>#{file.basename.to_s}</a></span>
        </td>
        <td class="type">#{type_description_for(file)}</td>
        } + 
        if !simple 
          %Q{           
          <td class="size">#{number_to_human_size(file.size)}</td>
          <td class="embed">#{link_or_embed_field_for(file)}</td>
          <td class="add-child"></td>
          <td class="remove">#{link_to_remove_file(file_id, asset_lock)}</td>        
          </tr>}
        else
          ''
        end
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
    
    IMAGE_EXTENSIONS = %w[png gif jpg jpeg]
    def image?(path)
      IMAGE_EXTENSIONS.find {|x| x.downcase == ext(path).downcase}
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
      %Q{<a href="#{http_path(path)}">#{path.basename} (#{type_description_for(path)}, #{number_to_human_size(path.size)})</a>}
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
    
    def expander(dont_expand)
      image(dont_expand ? "collapse" : "expand", 
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
