# Bài viết này gồm những nội dung chính sau:

1. Tạo một VPS với DigitalOcean (Ubuntu 14.04)
2. Cài đặt VPS cho Rails app để deploy (RVM, Git, Nginx, Passenger/Unicorn)
3. Tạo Rails app, cài đặt và deploy (Capistrano)

## Tạo một VPS với DigitalOcean

Hãy bắt đầu tạo VPS với [Digital Ocean](https://www.digitalocean.com/?refcode=e0e494858afd) - với mức giá và chất lượng rất tốt.
Chỉ với $10/month($0.015/hour) bạn đã có một droplet với 1GB RAM, 30GB SSD Disk, 2TB transfer...

![Droplet Name](https://dl.dropboxusercontent.com/u/64551181/october/Screenshot%202014-11-27%2012.54.26.png)

![Droplet Local](https://dl.dropboxusercontent.com/u/64551181/october/Screenshot%202014-11-27%2012.55.26.png)

![Droplet Create](https://dl.dropboxusercontent.com/u/64551181/october/Screenshot%202014-11-27%2012.57.26.png)


## Cài đặt VPS cho Rails app để deploy

Sau khi tạo VPS thành công bạn có thể dùng ssh hoặc ftp (Filezilla) để truy cập vào VPS, ở đây mình dùng ssh:

Nếu chưa tạo SSH key, hãy đọc bài viết này: https://help.github.com/articles/generating-ssh-keys/

In Terminal:
```ssh root@your_droplet_ip```

Nếu bạn gặp trường hợp tương tự như thế này:
```
[XX@XX ~]$ ssh root@pong
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the RSA key sent by the remote host is
6e:45:f9:a8:af:38:3d:a1:a5:c7:76:1d:02:f8:77:00.
Please contact your system administrator.
Add correct host key in /home/XX/.ssh/known_hosts to get rid of this message.
Offending RSA key in /var/lib/sss/pubconf/known_hosts:4
RSA host key for pong has changed and you have requested strict checking.
Host key verification failed.
```

Hãy ```ssh-keygen -R your_droplet_ip``` để thêm your_droplet_ip vào known_hosts

Sau khi bạn đã đăng nhập vào VPS với root user, hãy tạo một user để bắt đầu làm việc với app:

```sudo adduser deploy```

Thêm user deploy vào sudo group: ```sudo adduser deploy sudo```

File /etc/sudoers được cấu hình sẵn để cấp quyền cho tất cả member trong group (bạn không phải thay đổi gì trong file này)

```
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
```

Login vào deploy user: ```su deploy```

Mình khuyên bạn nên cài đặt đăng nhập user deploy bằng key để an toàn hơn.

Sử dụng ssh-copy-id để làm việc này, nếu bạn đang dùng Mac, chạy ```brew install ssh-copy-id``` để cài đặt ssh-copy-id

Chạy ở local (not VPS): ```ssh-copy-id deploy@your_droplet_ip```

### Cài đặt Ruby

#### Cài đặt dependencies cho Ruby:

```
sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
```

#### Cài đặt RVM

```
sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
curl -L https://get.rvm.io | bash -s stable
```

Nếu bị lỗi hãy thử:

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
# hoặc
command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
```

Sau đó chạy lại ```curl -L https://get.rvm.io | bash -s stable```

Update script và cài Ruby:

```
source ~/.rvm/scripts/rvm
echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc
rvm install 2.1.0
rvm use 2.1.0 --default
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
```

### Cài đặt Nginx

Bạn có thể sử dụng gói cài đặt nginx passenger của Phusion Passenger vì nó rất dễ cài đặt:

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

Sau khi cài đặt thành công passenger, chạy ```sudo service nginx start``` hoặc ```sudo service nginx ``` để xem usage:

```Usage: nginx {start|stop|restart|reload|force-reload|status|configtest|rotate|upgrade}```

Ngoài ra bạn có thể kiểm tra process bằng cách: ```ps aux | grep nginx```

Cấu hình Nginx:

```sudo nano /etc/nginx/nginx.conf``` hoặc ```sudo vi /etc/nginx/nginx.conf```

Uncomment hai dòng như bên dưới:

```
##
# Phusion Passenger
##
# Uncomment it if you installed ruby-passenger or ruby-passenger-enterprise
##

passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
passenger_ruby /usr/bin/ruby;
```

Đối với dòng passenger_ruby bạn chạy  ```which ruby``` sau đó sửa passenger_ruby theo đường dẫn đó, ví dụ:

```passenger_ruby /home/deploy/.rvm/rubies/ruby-2.1.0/bin/ruby;```

Bạn có thể edit file ```/etc/nginx/sites-enabled/default``` như sau:

```
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        passenger_enabled on;
        rails_env    production;
        root /var/www/your_app/current/public;
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


Mỗi lần bạn cấu hình Nginx hãy chạy ```sudo service nginx restart``` để khởi động lại Nginx.

### Cài đặt MySQL

```sudo apt-get install mysql-server mysql-client libmysqlclient-dev```

Check cài đặt ```mysql -u root -p``

## Cài đặt git và deploy (Capistrano)

### Cài đặt git

```
git remote add origin git@github.com:your_username/your_app.git
git config --global user.name "your_username"
git config --global user.email "your_email"
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

require 'capistrano/rvm'
require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'rvm1/capistrano3'
# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```

Bạn có thể cài đặt file ```config/deploy.rb``` như sau:

```
# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'matee'
set :repo_url, "git@github.com:your_username/your_app.git"

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/www/your_app'

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
set :linked_dirs, %w{public/uploads public/assets}

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

end

```

Để user deploy có thể restart nginx server:

```
sudo visudo
# Thêm vào dòng sau
deploy ALL=NOPASSWD:/etc/init.d/nginx
```

Dòng trên cho phép user deploy execute nginx start, stop và restart mà không cần password

Bạn có thể cấu hình file ```config/deploy/production.rb``` như sau

```
role :app, %w{deploy@your_droplet_ip}
role :web, %w{deploy@your_droplet_ip}
role :db,  %w{deploy@your_droplet_ip}

server '128.199.143.244', user: 'deploy', roles: %w{web}
```

### Let's deploy

In Terminal:
```
# in vps
deploy_to=/var/www/your_app
mkdir -p ${deploy_to}
chown deploy:deploy ${deploy_to}
umask 0002
chmod g+s ${deploy_to}
mkdir ${deploy_to}/{releases,shared}
chown deploy ${deploy_to}/{releases,shared}
```

Tao file database.yml 
```
su deploy
sudo nano /var/www/your_app/shared/config/database.yml
```

Cấu hình mysql cho app của bạn như sau:

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
  database:your_app_development

production:
  <<: *default
  database: your_app_production
```

Để tìm socket chính xác: ```vi /etc/mysql/my.cnf```  bạn sẽ thấy:

```
[client]
port            = 3306
socket          = /var/run/mysqld/mysqld.sock
```

Tạo file secrets.yml 

```
sudo nano /var/www/your_app/shared/config/secrets.yml
```

Điền vào file với nội dung như sau:

```
development:
  secret_key_base: your_development_key_here
production:
  secret_key_base: your_production_key_here
```

Bạn có thể tạo secret key bằng cách chạy ```rake secret``` ở your_app local folder

Tạo database:

```
mysql -u root -p
create database your_app_production;
```

In your_app local folder:

```RAILS_ENV=production cap production deploy```

Check your deploy:

```
# in vps
cd /var/www/your_app
ll
```

Bạn sẽ thấy thư mục current symlink đến bản releases 20141127094637 vừa deploy xong:

```
total 28
drwxr-sr-x 6 deploy deploy 4096 Nov 27 04:48 ./
drwxr-xr-x 3 root   root   4096 Nov 27 03:30 ../
lrwxrwxrwx 1 deploy deploy   38 Nov 27 04:48 current -> /var/www/your_app/releases/20141127094637/
drwxrwsr-x 5 deploy deploy 4096 Nov 27 04:46 releases/
drwxrwsr-x 7 deploy deploy 4096 Nov 27 04:33 repo/
-rw-rw-r-- 1 deploy deploy   70 Nov 27 04:48 revisions.log
drwxrwsr-x 2 deploy deploy 4096 Nov 27 03:36 rvm1scripts/
drwxrwsr-x 6 deploy deploy 4096 Nov 27 04:33 shared/
```

Tiếp tục:

```
cd current
ll config
```

Symlink của database.yml và secrets.yml nhằm mục đích an toàn:

```
total 44
drwxrwsr-x  7 deploy deploy 4096 Nov 27 04:46 ./
drwxrwsr-x 14 deploy deploy 4096 Nov 27 04:48 ../
-rw-rw-r--  1 deploy deploy 1436 Nov 13 09:09 application.rb
-rw-rw-r--  1 deploy deploy  170 Nov 13 09:09 boot.rb
lrwxrwxrwx  1 deploy deploy   41 Nov 27 04:46 database.yml -> /var/www/your_app/shared/config/database.yml
-rw-rw-r--  1 deploy deploy  150 Nov 13 09:09 environment.rb
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 environments/
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 initializers/
drwxrwsr-x  5 deploy deploy 4096 Nov 13 09:09 locales/
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 routes/
-rw-rw-r--  1 deploy deploy 1653 Nov 13 09:09 routes.rb
lrwxrwxrwx  1 deploy deploy   40 Nov 27 04:46 secrets.yml -> /var/www/your_app/shared/config/secrets.yml
drwxrwsr-x  2 deploy deploy 4096 Nov 13 09:09 settings/
-rw-rw-r--  1 deploy deploy    0 Nov 13 09:09 settings.yml
```

Chạy passenger để test:

```
gem install daemon_controller
bin/rake db:create db:migrate
RAILS_EVN=production passenger start
```

Sau đó bạn dùng trình duyệt vào http://your_droplet_ip:3000 để thấy app của bạn.

## Tham khảo thêm:
https://www.digitalocean.com/community/tutorials/how-to-configure-the-nginx-web-server-on-a-virtual-private-server
https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#rubygems_generic_install
http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/
https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps
https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7

