#
# Cookbook Name:: base
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'apt::default' # ensure apt-update runs

%w(curl lsof).each do |p|
  package p
end

httpd_service 'default' do
  action [:create, :start]
end
