require 'fileutils'
require 'pathname'

root_path = Pathname.new(File.dirname(__FILE__)).parent
tmpdir = root_path.join('tmp', 'emoji-tmp')

unless Dir.exist?(tmpdir)
  %x[git clone https://github.com/arvida/emoji-cheat-sheet.com.git #{tmpdir}]
else
  %x[cd #{tmpdir} && git pull origin master --verbose]
end

json_result = 'var emoji_map = {'

File.open(root_path.join('tmp', 'emoji-tmp', 'public', 'index.html')) do |file|
  file.each_line do |line|
    if /img src="\S+?\/(?<img_src>\S+?)"> \:<span class="name">(?<type_this>\S+?)<\/span>\:<\/div/ =~ line
      json_result += '"' + type_this + '":"/img/' + img_src + '",'
      FileUtils.cp(root_path.join('tmp', 'emoji-tmp', 'public', 'graphics').to_s + '/' + img_src, root_path.join('public', 'img', 'emojis'))
    end
  end
end

json_result = json_result[0...-1]
json_result += '}'

json_file = File.new(root_path.join('assets', 'js').to_s + '/emoji.js', 'w')
json_file.write(json_result)
json_file.close
