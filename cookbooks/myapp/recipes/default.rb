#
# Cookbook Name:: myapp
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

version = '0.0.1'
build   = build_number

httpd_config 'myapp' do
  source 'myapp.erb'
  notifies :restart, 'httpd_service[default]'
end

template '/var/www/index.html' do
  variables({ version: version, build: build })
  source 'myapp_html.erb'
  action :create
end
