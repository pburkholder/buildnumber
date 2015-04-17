# See http://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "pdb"
client_key               "#{current_dir}/pdb.pem"
#validation_client_name   "pdb_org"
#validation_key           "#{current_dir}/pdb_org.pem"
chef_server_url          "https://chefserver.cheffian.com/organizations/pdb_org"

cookbook_path            [
                            "#{current_dir}/..",
                            "#{current_dir}/../cookbooks"
                          ]

use_policyfile true
policy_document_native_api true

#policy_name 'jenkins'
#policy_group 'dev'
