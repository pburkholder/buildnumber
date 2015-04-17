require 'json'

def json_path(json_file='build.json')
    File.join(File.dirname(__FILE__), '../files/default/' + json_file)
end

def build_number(json='build.json')
    build_data=JSON.parse(File.read(json_path(json)))
    return build_data['build']
end
