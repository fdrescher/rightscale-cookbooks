## This recipe is not intended to be called directly
# its returns server_fqdn
# THIS IS ONLY AN EXAMPLE: It is not best practise to return a value from an recipe include!!!

rs_utils_marker :begin

r = server_collection 'load_balancer' do
  tags [
    "loadbalancer:lb=#{node[:lb_haproxy][:applistener_name]}"
  ]
  action :nothing
end

# get the tags in the compile phase
r.run_action(:load)

if node[:server_collection]['load_balancer'].empty?
  Chef::Log.warn "No load-balancer found."
else
  # 
  lb_servers = node[:server_collection]['load_balancer'].to_hash.values.map do |tags|
    RightScale::Utils::Helper.get_tag_value('server:public_ip_0', tags)
  end
  
  if lb_servers.length() > 1
    raise "More than one load-balancer found."
  end
  
  lb_host = lb_servers.first()

  Socket.do_not_reverse_lookup = false
  s = Socket.getaddrinfo(lb_host,nil)
  server_fqdn = s[0][2]
end

rs_utils_marker :end
