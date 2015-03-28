#!/usr/bin/env ruby
## Copyright 2015 Mellanox Technologies, Ltd
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
## implied.
## See the License for the specific language governing permissions and
## limitations under the License.

require 'hiera'
ENV['LANG'] = 'C'
LOG_FILE="/var/log/mellanox_plugin.log"

def log(level, msg)
  current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  File.open(LOG_FILE, 'a') { |f|
    f.puts "#{current_time} delete_images.rb #{level}: #{msg}"
  }
end

def image_list
  stdout = `. /root/openrc && glance image-list`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

def images_ids
  stdout, return_code = image_list
  if return_code != 0
    raise 'Failed retrieving image-list'
  end
  ids = []
  stdout.split("\n").each do |line|
    fields = line.split('|').map { |f| f.chomp.strip }
    next if fields[1] == 'ID'
    next unless fields[1]
    ids << fields[1]
  end
  {:ids => ids, :exit_code => return_code}
end


def delete_image(id)
  command = ". /root/openrc && /usr/bin/glance image-delete #{id}"
  stdout = `#{command}`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

def wait_for_glance
  5.times.each do |retries|
    sleep 10 if retries > 0
    _, return_code = image_list
    return if return_code == 0
  end
  raise 'Could not get a list of glance images!'
end

def main
  log("info", "Waiting for glance response")
  wait_for_glance

  log("info", "Fetching list of current images")
  ids = images_ids
  if ids[:exit_code] != 0
    raise 'Failed retrieving existing images ids'
  end

  succeed = true
  ids[:ids].each do |id|
    stdout, return_code = delete_image(id)
    if return_code != 0
      log("error", "Failed deleting image with ID = '#{id}'" + stdout)
      succeed = false
    end
  end
  if ! succeed
    log("error", "Some images weren't deleted, this may cause errors when "
                 "uploading images to glance or when creating an instance"
  end
end

########################

begin
  main
rescue
  log("error", "Some images weren't deleted, this may cause errors when " +
               "uploading images to glance or when creating an instance")
  exit 1
else
  log("info", "Successfully deleted all existing images from glance")
end
