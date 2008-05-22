require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::FileHelper do
  scenario :users  
  
  before do
    @asset_absolute_path = Pathname.new(FileBrowserExtension.asset_path)
    test_dir = Pathname.new(File.join(@asset_absolute_path, 'Test1'))
    test_file = Pathname.new(File.join(@asset_absolute_path, 'testfile.jpg'))
    Dir.mkdir(test_dir)
    file = File.open(test_file, 'w+') {|f| f.write("Hello World") }
    @file_size = number_to_human_size(file.size)
    @test_dir_id = path2id(test_dir).to_s
    @test_file_id = path2id(test_file).to_s
  end

  before :each do
    login_as :admin
  end
  
  #Delete this example and add some real ones or delete this file
  it "should include the Admin::FileHelper" do
    included_modules = self.metaclass.send :included_modules
    included_modules.should include(Admin::FileHelper)
  end
  
  it "should display a directory" do
    render_html = render_children @asset_absolute_path
    str = '<tr class="node level-1 children-hidden" id = "page-'+@test_dir_id+'" >(\s)*'
    str += '<td class="directory" style="padding-left: 26px">(\s)*'
    str += '<span class="w1">(\s)*'
    str += '<img alt="toggle children" class="expander" src="/images/admin/expand.png\?(\d)*" title="" />(\s)*'
    str += '<img alt="" class="icon" src="/images/admin/page.png\?(\d)*" />(\s)*'
    str += '<span class="title">Test1</span>(\s)*'
    str += '<img alt="" class="busy" id="busy-'+@test_dir_id+'" src="/images/admin/spinner.gif\?(\d)*" style="display: none;" title="" />(\s)*'
    str += '</span>(\s)*'
    str += '</td>(\s)*'
    str += '<td class="type">Folder</td>(\s)*'
    str += '<td class="size"></td>(\s)*'
    str += '<td class="embed"></td>(\s)*'
    str += '<td class="add-child"><a href="/admin/files/new\?parent_id='+@test_dir_id+'"><img alt="add child" src="/images/admin/add-child.png\?(\d)*" /></a></td>(\s)*'
    str += '<td class="remove"><a href="/admin/files/remove\?id='+@test_dir_id+'"><img alt="remove page" src="/images/admin/remove.png\?(\d)*" /></a></td>(\s)*'
    str += '</tr>(\s)*'
    render_html.should match(Regexp.new(str))
  end
  
  it "should display a file" do
    render_html = render_children @asset_absolute_path    
    str = '<tr class="node level-1 no-children" id = "page-'+@test_file_id+'">(\s)*'    
    str += '<td class="file" style="padding-left: 26px">(\s)*'
    str += '<img alt="" class="icon" src="/images/admin/page.png\?(\d)*" />(\s)*'
    str += '<span class="title">testfile.jpg</span>(\s)*'
    str += '</td>(\s)*'
    str += '(\s)*'
    str += '<td class="type">JPG Image</td>(\s)*'
    str += '<td class="size">(\d)+ Bytes</td>(\s)*'
    str += '<td class="embed">(\s)*'
    str += '<input type="text" value="&lt;r:img src=&quot;testfile.jpg&quot; /&gt;"(\s)*'
    str += 'style="width: 100%"(\s)*'
    str += 'onclick="this.focus\(\);this.select\(\)" />(\s)*'
    str += '</td>(\s)*'
    str += '<td class="add-child"></td>(\s)*'
    str += '<td class="remove"><a href="/admin/files/remove\?id='+@test_file_id+'"><img alt="remove page" src="/images/admin/remove.png\?(\d)*" /></a></td>(\s)*'
    str += '(\s)*'
    str += '</tr>(\s)*'
    
    render_html.should match(Regexp.new(str))    
  end
  
  after do
    test_dir = File.join(@asset_absolute_path, 'Test1') 
    test_file = File.join(@asset_absolute_path, 'testfile.jpg') 
    Pathname.new(test_dir).rmdir
    Pathname.new(test_file).delete    

  end
  
end
