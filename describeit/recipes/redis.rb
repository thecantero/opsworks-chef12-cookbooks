package "tcl8.5"

# download redis
remote_file "/home/#{node['user']['name']}/redis-#{node['redis']['version']}.tar.gz" do
  source "http://download.redis.io/releases/redis-#{node['redis']['version']}.tar.gz"
  mode 0644
  action :create_if_missing
end

# install redis
bash 'install redis' do
  cwd "/home/#{node['user']['name']}"
  code <<-EOH
    tar xzf redis-#{node['redis']['version']}.tar.gz
    cd redis-#{node['redis']['version']}
    make && make install
  EOH
  not_if { File.exists?("/usr/local/bin/redis-server") &&
           `redis-server --version`.chomp.split[2] == "v=#{node['redis']['version']}" }
end

# install redis server
execute "curl -L https://gist.githubusercontent.com/vladigleba/28f4f6b4454947c5223e/raw | sh" do
  cwd "/home/#{node['user']['name']}/redis-#{node['redis']['version']}/utils"
  not_if "ls /etc/init.d | grep redis"
end


ruby_block "insert_line to redis config" do
  block do
    file = Chef::Util::FileEdit.new("/etc/redis/6379.conf")
    file.insert_line_if_no_match("/customredis/", "include /etc/redis/customredis.conf")
    file.write_file
  end
end

execute "sudo restart redis" do
  action :nothing
end

# create .bash_profile file
cookbook_file "/etc/redis/customredis.conf" do
  source "customredis.conf"
  mode 0644
  notifies :restart, "execute[sudo restart redis]", :delayed
end
