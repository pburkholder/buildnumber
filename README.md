# policyfiles and builds

Demonstrate use of policyfiles to emulate build number increments.


## Scenario

We assume some build process that bundles a Chef cookbook as the generated artifact, and then includes that cookbook in the run_list of nodes in the same env:

    run_list: 'recipe[base@0.1.0], recipe[myapp@0.1.0]'

However, the myapp recipe configure index.html via a template to render the build number as well:

    <h1>Welcome to myapp</h1>
    <ul>
     <li>Version: 0.1.0</li>
     <li>Build: 1001</li>
    </ul>

The 'base' recipe is unchanged in each build, but the 'myapp' recipe has an data_file that is incremented with each build.

Builds are generated and tested on ephemeral nodes. The build are pushed as the policy for the role 'myapp', and are labelled with policy_groups that correspond to each build, e.g.:

- myapp-0.1.0-0
- myapp-0.1.0-1

When build myapp-0.1.0-1 passes, then it's promoted to the 'prod' policy_group and then the 'prod' node converges with that new policy based on the bundled cookbooks.

## Chef Server setup

No recipe for this yet. DNS is chefserver.cheffian.com. To do:

- install chef-server 12.0.7 per https://www.chef.io/blog/2015/03/27/chef-server-12-0-7-released/
- `/etc/opscode/chef-server.rb` (you need to run chef-server-ctl reconfigure to make it take effect):

      lb["xdl_defaults"]["policies"] = true
      api_fqdn 'chefserver.cheffian.com'
      # NOT SURE IF NEEDED:


- create a user and an organization with that user associated (`-a`):
      sudo chef-server-ctl user-create pdb Peter Burkholder pburkholder@chef.io TestPassword -f pdb.pem
      sudo chef-server-ctl org-create pdb_org pdb_org -f pdb_org.pem -a pdb
- make `current_dir/.chef/knife.rb` and copy the above .pem file into the `.chef` directory:
      cd .chef
      scp ubuntu@chefserver.cheffian.com:pdb.pem .
      scp ubuntu@chefserver.cheffian.com:pdb_org.pem .
- fetch the ssl cert:
      knife ssl fetch https://chefserver.cheffian.com
- test with `knife user list`:


## Cookbooks and Clients:

### First lets get the simplest case down

Commit `pdb/policyfile 0211fbb`is where I have base cookbook installing httpd, and the myapp cookbook installing the index.html with build number from `libraries/build.json`. The `kitchen verify` should pass.

### Onwards and local setup

Install 0.5.0 of ChefDK:

    curl "http://www.chef.io/chef/metadata-chefdk?p=mac_os_x&pv=10.10&m=x86_64&prerelease=true"

Update knife.rb with add'l configuration parameters:

    use_policyfile true
    policy_document_native_api true

    #policy_name 'jenkins'
    #policy_group 'dev'


Now I create `cookbooks/myapp/Policyfile.rb` and run `chef install -D`:

    chef install -D
    Building policy myapp
    Expanded run list: recipe[base], recipe[myapp]
    Caching Cookbooks...
    Installing base  >= 0.0.0 from path
    Installing myapp >= 0.0.0 from path
    Installing apt   2.7.0
    Installing httpd 0.2.11

and push that as 'myapp-0.1.0-0' using the 'policygroup' feature

    chef push myapp-0.1.0-0
    Uploading policy to policy group myapp-0.1.0-0
    WARN: Using native policy API preview mode. You may be required to delete and
    re-upload this data when upgrading to the final release version of the feature.
    Uploaded base  0.1.0  (f5cdaad1)
    Uploaded myapp 0.1.0  (81a87a95)
    Uploaded apt   2.7.0  (16c57abb)
    Uploaded httpd 0.2.11 (3c562c6a)

## Try it on a node

I have set up in aws the nodes 'p0.cheffian.com', 'p1....', and 'p2....'

Not setting any runlist the first time, then going back and editing client.rb to use the Policyfile endpoints and features.

    knife bootstrap p0.cheffian.com -x ubuntu -r '' -N p0 --sudo

    # Note that my pdb_org.pem didn't work so I rm the validation lines
    # from knife.rb to use my personal creds

then on `p0.cheffian.com` set policy_name and policy_group:

    log_location     STDOUT
    chef_server_url  "https://chefserver.cheffian.com/organizations/pdb_org"
    validation_client_name "chef-validator"
    node_name "p0"
    trusted_certs_dir "/etc/chef/trusted_certs"

    use_policyfile true
    policy_document_native_api true
    policy_name  'myapp'
    policy_group 'myapp-0.1.0-0'

and that works.

Now I tag build 0.1.0-0 and push that to our origin git repo.

## Now build 1

### on the workstation:

We change `myapp/files/default/build.json` to build 1, and:

    rm Policyfile.lock.json

and re-run:

    chef install -D

to update the Policyfile.lock.json. Then:

    chef push myapp-0.1.0-1

    git commit -am "0.1.0-1"
    git tag -m 0.1.0-1 0.1.0-1
    git push origin master
    git push origin 0.1.0-1

OR: just run `rake bump build tag`

### Now lets set up the target node:

bootstrap the node:

    knife bootstrap p1.cheffian.com -x ubuntu -r '' -N p1 --sudo

Then:

    ssh p1.cheffian.com
    sudo bash
    cd /etc/chef

    cat >> client.rb
    use_policyfile true
    policy_document_native_api true
    policy_name  'myapp'
    policy_group 'myapp-0.1.0-1'
     ^D

Lastly run the client and confirm

    sudo chef-client
    curl localhost

### Lastly we promote this build of myapp to prod

Here we go:

    git checkout 0.1.0-1
    chef push prod
    chef push prod
      Uploading policy to policy group prod
      WARN: Using native policy API preview mode. You may be required to delete and
      re-upload this data when upgrading to the final release version of the feature.
      Using    base  0.1.0  (fc79b25d)
      Using    apt   2.7.0  (16c57abb)
      Using    httpd 0.2.11 (3c562c6a)
      Uploaded myapp 0.1.0  (90a39ad0)

Check with `knife raw` the policy for 'myapp' in the 'prod' policy_group

    knife raw /policy_groups/prod/policies/myapp | egrep -B2 \"identifier
        "base": {
          "version": "0.1.0",
          "identifier": "fc79b25dc1ac842bdf342a65a2dda0d83d929c12",
    --
        "myapp": {
          "version": "0.1.0",
          "identifier": "90a39ad0ad73ff3b245e1c5ede2a60a437349a73",
    --
        "apt": {
          "version": "2.7.0",
          "identifier": "16c57abbd056543f7d5a15dabbb03261024a9c5e",
    --
        "httpd": {
          "version": "0.2.11",
          "identifier": "3c562c6ac6ac554b4a11a0ad4c522fab246bf8b3",


The prod node always has the 'prod policy group' as in the this '/etc/chef/client.rb':

    log_location     STDOUT
    chef_server_url  "https://chefserver.cheffian.com/organizations/pdb_org"
    validation_client_name "chef-validator"
    node_name "prod"
    trusted_certs_dir "/etc/chef/trusted_certs"

    use_policyfile true
    policy_document_native_api true
    policy_name  'myapp'
    policy_group 'prod'

And now that we've promoted to 'prod' policygroup the chef-client run produces this html:

    <h1>Welcome to myapp</h1>
    <ul>
      <li>Version: 0.1.0</li>
      <li>Build: 1 </li>
    </ul>

Fini.
