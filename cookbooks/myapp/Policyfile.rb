# Policyfile.rb
name "myapp"
default_source :community
run_list "base", "myapp"
cookbook "base", path: "../base"
cookbook "myapp", path: "../myapp"
