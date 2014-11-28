# Bài viết này gồm những nội dung chính sau:

1. Tạo một VPS với DigitalOcean (Ubuntu 14.04)
2. Cài đặt VPS cho Rails app để deploy (RVM, Git, Nginx, Passenger/Unicorn)
3. Tạo Rails app, cài đặt và deploy (Capistrano)

## Tạo một VPS với DigitalOcean

Hãy bắt đầu tạo VPS với [Digital Ocean](https://www.digitalocean.com/?refcode=e0e494858afd) - với mức giá và chất lượng rất tốt.
Chỉ với $10/month($0.015/hour) bạn đã có một droplet với 1GB RAM, 30GB SSD Disk, 2TB transfer...

![Image of Yaktocat](https://www.dropbox.com/s/9mymjklmq0nvq16/Screenshot%202014-11-06%2015.48.55.png?dl=0)

## Cài đặt VPS cho Rails app để deploy

Sau khi tạo VPS thành công bạn có thể dùng ssh hoặc ftp (Filezilla) để truy cập vào VPS, ở đây mình dùng ssh

Neu chua co ssh key: https://help.github.com/articles/generating-ssh-keys/

In Terminal: 
```ssh root@128.199.143.244```
Nếu (ảnh) thì:
```ssh-keygen -R 128.199.143.244```

Sau khi bạn đã đăng nhập vào VPS với root user, hãy tạo một user để bắt đầu làm việc với app.
```sudo adduser deploy```
Add user deploy vào sudo group: ```sudo adduser deploy sudo```
/etc/sudoers is pre-configured to grant permissions to all members of this group (You should not have to make any changes to this):
```
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
```

```
sudo visudo
deploy ALL=NOPASSWD:/etc/init.d/nginx
```

The above line let’s our deploy user execute the nginx start, stop and restart commands without supplying a password (although he still has to put sudo in front of the command). You need to specify full paths for every command you want to replace deploy with the correct user name.

Login vào deploy user: ```su deploy```

Before we move forward is that we're going to setup SSH to authenticate via keys instead of having to use a password to login. It's more secure and will save you time in the long run.

We're going to use ssh-copy-id to do this. If you're on OSX you may need to run brew install ssh-copy-id but if you're following this tutorial on Linux desktop, you should already have it.

Once you've got ssh-copy-id installed, run the following and replace IPADDRESS with the one for your server:
Chạy ở local (not VPS): ```ssh-copy-id deploy@128.199.143.244```

### Cài đặt Ruby

#### Cài đặt một số dependencies cho Ruby:
```
sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```

#### Cài đặt RVM

```
sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
curl -L https://get.rvm.io | bash -s stable
```
Nếu bị lỗi hãy thử ``gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3```
hoặc ```command curl -sSL https://rvm.io/mpapis.asc | gpg --import -``` nếu không được
Sau đó chạy lại ```curl -L https://get.rvm.io | bash -s stable```

```
source ~/.rvm/scripts/rvm
echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc
rvm install 2.1.0
rvm use 2.1.0 --default
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
```

### Cài đặt Nginx

Phusion is the company that develops Passenger and they recently put out an official Ubuntu package that ships with Nginx and Passenger pre-installed.

We'll be using that to setup our production server because it's very easy to setup.
```
# Install Phusion's PGP key to verify packages
gpg --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
gpg --armor --export 561F9B9CAC40B2F7 | sudo apt-key add -

# Add HTTPS support to APT
sudo apt-get install apt-transport-https

# Add the passenger repository
sudo sh -c "echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' >> /etc/apt/sources.list.d/passenger.list"
sudo chown root: /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get update

# Install nginx and passenger
sudo apt-get install nginx-full passenger
```

```sudo service nginx start``` hoặc ```sudo service nginx ``` để xem usage:
```Usage: nginx {start|stop|restart|reload|force-reload|status|configtest|rotate|upgrade}```
Ngoài ra bạn có thể kiểm tra qua: ```ps aux | grep nginx```

```sudo nano /etc/nginx/nginx.conf``` hoặc ```sudo vi /etc/nginx/nginx.conf```

Find the following lines, and uncomment them:

```
##
# Phusion Passenger
##
# Uncomment it if you installed ruby-passenger or ruby-passenger-enterprise
##

passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
passenger_ruby /usr/bin/ruby;
```

Chạy ```which ruby``` sau đó sửa passenger_ruby theo đường dẫn đó, ví dụ:

```passenger_ruby /home/deploy/.rvm/rubies/ruby-2.1.0/bin/ruby;```

Configure nginx:

Bạn có thể edit file ```/etc/nginx/sites-enabled/default``` như sau:

```
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        passenger_enabled on;
        rails_env    production;
        root /var/www/matee/current/public;
        #index index.html index.htm;

        # Make site accessible from http://localhost/
        server_name localhost;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
                # Uncomment to enable naxsi on this location
                # include /etc/nginx/naxsi.rules
        }
}
```

Once you've changed passenger_ruby to use the right version Ruby, you can run ```sudo service nginx restart``` to restart Nginx with the new Passenger configuration.

### Cài đặt MySQL

```sudo apt-get install mysql-server mysql-client libmysqlclient-dev```

Check cài đặt ```mysql -u root -p``

## Tạo Rails app, cài đặt và deploy (Capistrano)

### Tạo Rails app

Nếu bạn đã có sẵn Rails app và cài đặt git, vui lòng bỏ qua bước này

```
# Create a sample Rails application
rails new my_app

# Enter the application directory
cd my_app

# Create a sample resource
rails generate scaffold Task title:string note:text

# Create a sample database
RAILS_ENV=development rake db:migrate

# Enter the application directory
cd my_app

# Run a simple server
rails s
```

### Cài đặt git

```
# Initiate the repository
git init

# Add all the files to the repository
git add .

# Commit the changes
git commit -m "first commit"

# Add your Github repository link 
# Example: git remote add origin git@github.com:[user name]/[proj. name].git
git remote add origin git@github.com:user123/my_app.git

# Create an RSA/SSH key
# Follow the on-screen instructions
ssh-keygen -t rsa

# View the contents of the key and add it to your Github
# by copy-and-pasting from the current remote session by
# visiting: https://github.com/settings/ssh
# To learn more about the process,
# visit: https://help.github.com/articles/generating-ssh-keys
cat /root/.ssh/id_rsa.pub

# Set your Github information
# Username:
# Usage: git config --global user.name "[your username]"
git config --global user.name "user123"

# Email:
# Usage: git config --global user.email "[your email]"
git config --global user.email "user123@domain.tld"

# Push the project's source code to your Github account
git push -u origin master
```

### Cài đặt Capistrano
Thêm vào Gemfile, sau đó ```bundle install```
Nếu bạn sử dụng passenger làm Rails server:
```
gem "passenger"
gem "capistrano", "~> 3.2.0"
gem "capistrano-rails", "~> 1.1"
```
Nếu bạn sử dụng unicorn làm Rails server:

```
gem "unicorn"
gem "capistrano", "~> 3.2.0"
gem "capistrano-rails", "~> 1.1"
```

Capify: make sure there's no "Capfile" or "capfile" present
```bundle exec cap install```
More: https://github.com/capistrano/capistrano

Kiểm tra Capfile, chắc chắn đủ những dòng sau:
```
# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
require 'capistrano/rvm'
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'rvm1/capistrano3'
# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```n

Bạn có thể cài đặt your_app/config/deploy.rb như sau:
```
# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'matee'
set :repo_url, "git@github.com:nhattan/matee.git"

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/www/matee'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/secrets.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{public/uploads public/assets}

# Default value for default_env is {}
set :default_env, { path: "/usr/local/rvm/gems/ruby-2.1.0@global/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 1 do
      execute "sudo /etc/init.d/nginx restart"
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 1 do

      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
```

File ```config/deploy/production.rb```

```
role :app, %w{deployer@128.199.143.244}
role :web, %w{deployer@128.199.143.244}
role :db,  %w{deployer@128.199.143.244}

server '128.199.143.244', user: 'deployer', roles: %w{web}

set :ssh_options, {
 keys: %w(/home/deployer/.ssh/id_rsa),
 forward_agent: false,
 auth_methods: %w(password),
 password: "deployer"
}

```

### Let's deploy

In Terminal:
```
ssh root@remote
deploy_to=/var/www/your_app
mkdir -p ${deploy_to}
chown deploy:deploy ${deploy_to}
umask 0002
chmod g+s ${deploy_to}
mkdir ${deploy_to}/{releases,shared}
chown deploy ${deploy_to}/{releases,shared}
```

Note: The chmod g+s is a really handy, and little known Unix feature, it means that at the operating system level, without having to pay much attention to the permissions at runtime, all files an directories created inside the ${deploy_to} directory will inherit the group ownership, that means in this case even though we are root, the files will be created being owned by root with the group deploy, the umask 0002 ensures that the files created during this session are created with the permissions owner read/write, group: read/write, other: none. This means that we'll be able to read these files from Apache, or our web server by running the web server in the deploy group namespace.

Tao file database.yml 
```
su deploy
sudo nano /var/www/matee/shared/config/database.yml
```
Dien vao nhu sau:

```
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password: your_root_password
  socket: /var/run/mysqld/mysqld.sock

development:
  <<: *default
  database: matee_development

production:
  <<: *default
  database: matee_production
```

Socket:

``vi /etc/mysql/my.cnf```  you will see:

```
[client]
port            = 3306
socket          = /var/run/mysqld/mysqld.sock
```

Tao file secrets.yml 
```
sudo nano /var/www/matee/shared/config/secrets.yml
```

Dien vao file nhu sau:
```
development:
  secret_key_base: your_development_key_here
production:
  secret_key_base: your_production_key_here
```

Ban co the tao key bang cach ```rake secret``` o local root rails app folder cua ban

Tao database cho rails app:
```
mysql -u root -p
create database matee_production;
```

In Terminal:

```RAILS_ENV=production cap production deploy```


Check your deploy:

```
cd /var/www/matee
ll
```
Ban se thay:
```
total 28
drwxr-sr-x 6 deploy deploy 4096 Nov 27 04:48 ./
drwxr-xr-x 3 root   root   4096 Nov 27 03:30 ../
lrwxrwxrwx 1 deploy deploy   38 Nov 27 04:48 current -> /var/www/matee/releases/20141127094637/
drwxrwsr-x 5 deploy deploy 4096 Nov 27 04:46 releases/
drwxrwsr-x 7 deploy deploy 4096 Nov 27 04:33 repo/
-rw-rw-r-- 1 deploy deploy   70 Nov 27 04:48 revisions.log
drwxrwsr-x 2 deploy deploy 4096 Nov 27 03:36 rvm1scripts/
drwxrwsr-x 6 deploy deploy 4096 Nov 27 04:33 shared/
```

```
cd current
ll config
```

```
total 44
drwxrwsr-x  7 deploy deploy 4096 Nov 27 04:46 ./
drwxrwsr-x 14 deploy deploy 4096 Nov 27 04:48 ../
-rw-rw-r--  1 deploy deploy 1436 Nov 13 09:09 application.rb
-rw-rw-r--  1 deploy deploy  170 Nov 13 09:09 boot.rb
lrwxrwxrwx  1 deploy deploy   41 Nov 27 04:46 database.yml -> /var/www/matee/shared/config/database.yml
-rw-rw-r--  1 deploy deploy  150 Nov 13 09:09 environment.rb
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 environments/
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 initializers/
drwxrwsr-x  5 deploy deploy 4096 Nov 13 09:09 locales/
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 routes/
-rw-rw-r--  1 deploy deploy 1653 Nov 13 09:09 routes.rb
lrwxrwxrwx  1 deploy deploy   40 Nov 27 04:46 secrets.yml -> /var/www/matee/shared/config/secrets.yml
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 settings/
-rw-rw-r--  1 deploy deploy    0 Nov 13 09:09 settings.yml
```

```
gem install daemon_controller
bin/rake db:create db:migrate
RAILS_EVN=production passenger start
```

Ban co the truy cap vao http://your_droplet_address:3000 de thay app cua ban hoat dong!
