require 'spec_helper'

describe 'myapp::default' do

  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html
  
  describe command("curl -L localhost | grep -a 'Build:'") do
        its(:exit_status) { should eq 0 }
  end

end
