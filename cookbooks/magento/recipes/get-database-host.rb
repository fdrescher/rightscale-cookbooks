## This recipe is not intended to be called directly

rs_utils_marker :begin

r = server_collection 'database' do
  tags [
    "database:active=true"
  ]
  action :nothing
end
  
# get the tags in the compile phase
r.run_action(:load)

if node[:server_collection]['database'].empty?
  raise "No database found."
else
  # 
  database_servers = node[:server_collection]['database'].to_hash.values.map do |tags|
    RightScale::Utils::Helper.get_tag_value('server:private_ip_0', tags)
  end
  
  if database_servers.length() > 1
    raise "More than one database found."
  end
  node.set[:tmp][:db_host] = database_servers.first()
end

rs_utils_marker :end
