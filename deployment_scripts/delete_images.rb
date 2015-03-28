#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

def image_list
  stdout = `. /root/openrc && glance image-list`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

def images_ids
  stdout, return_code = image_list
  if return_code != 0
    puts 'Failed retrieving image-list'
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
  puts command
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


########################

wait_for_glance

ids = images_ids
if ids[:exit_code] != 0
  raise 'Failed retrieving existing images ids'
end

succeed = true
ids[:ids].each do |id|
  stdout, return_code = delete_image(id)
  if return_code != 0
    puts "Failed deleting image with ID = '#{id}'"
    puts stdout
    succeed = false
  end
end

succeed
