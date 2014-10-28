# Phần 1: Làm quen với Angular

Một ứng dụng "CRUD" cơ bản khó thể hiện hết sức mạnh của Angular nhưng lại dễ hiểu, đặc biệt cho Rails developers. Phần khó nhất và nhàm chán nhất của việc học một công nghệ mới là phần cài đặt:

1. Tạo một ứng dụng Rails, thêm vào một số gem cần thiết

2. Cài đặt Bower để quản lý front-end dependencies

3. Làm một ví dụ đơn giản với Angular

4. Deploy lên server để đảm bảo asset pipeline hoạt động

## Chuẩn bị ứng dụng Rails và Bower

```ruby
rails new hbc
cd hbc
```

Những Gem cơ bản
Thêm vào Gemfile sau đó ```bundle install```
```ruby
gem "sass"
```

Gem ``` bower-rails``` cung cấp cách quản lý các dependencies giống như Gemfile, nó cung cấp cho chúng ta nhiều thư viện hơn đối với một Rails app thông thường.

Đầu tiên ta phải cài Bower - JavaScript command line application. Nhưng trước hết phải cài npm - "Node Package Manager"

```
brew install node
npm install bower
````

Thêm ```gem "bower-rails"``` vào Gemfile sau đó ```bundle install```
```
rails g bower_rails:initialize
```

Bower hoạt động tương tự như Bundler, cung cấp những tác vụ sau:
```
> rake -T bower
rake bower:install        # Install components from bower
rake bower:install:force  # Install components with -F option
rake bower:list           # List bower components
rake bower:resolve        # Resolve assets paths in bower components
rake bower:update         # Update bower components
rake bower:update:prune   # Update existing components and uninstalls extraneous components
```

Dependencies được khai báo trong file có tên ```Bowerfile``` nằm ở thư mục gốc của Rails app, sử dụng như Gemfile.
Thêm vào Bowerfile hai thư viện:
```
asset 'angular'
asset 'bootstrap-sass-official'
```

```bower:install``` để install dependencies

Bower cài dependencies trong thư mục ```vendor/assets/bower_components```

Vì ```vendor/assets/bower_components``` không theo chuẩn Rails nên bạn phải thêm nó vào asset path.

Thêm vào ```config/application.rb```

```ruby
config.assets.paths += Dir[Rails.root.join("vendor","assets","bower_components")]
config.assets.paths += Dir[Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")]
```
Cuối cùng bạn phải reference những file đó vào ```application.js``` và ```application.css.scss```. Trước tiên, đổi tên ```application.css``` thành ```application.css.scss``` để sử dụng Boostrap.

Tương tự thêm vào ```application.js``` và ```application.css.scss```
```
app/assets/javascripts/application.js
//= require angular/angular
```

```
app/assets/stylesheets/application.css.scss
@import "bootstrap-sass-official/assets/stylesheets/bootstrap-sprockets";
@import "bootstrap-sass-official/assets/stylesheets/bootstrap";
```


# Làm một ví dụ đơn giản với Angular

Thêm vào ```routes.rb```
```ruby
root 'home#index'
```

Sau đấy tạo một controller ```HomeController```
```ruby
class HomeController < ApplicationController
  def index
  end
end
```

Tạo sườn cho Angular app, đặt trong ```app.coffee```:
```
hbc = angular.module('hbc',[
])
```


Với Angular, ta sẽ map routes đến views và controllers như sau:
```
app.config([ '$routeProvider',
  ($routeProvider)->
    $routeProvider
      .when('/',
        templateUrl: "index.html"
        controller: 'SomeController'
      )
      .when('/recipes/new',
        templateUrl: "new.html"
        controller: 'SomeOtherController'
      )
])
```

Tuy nhiên trong môi trường production, asset pipeline sẽ điều kiển đường dẫn và tên của asset mà nó đang phục vụ. Nó sẽ tạo một hash cho mỗi asset và thêm hash đó vào tên. Điều đó có nghĩa là nếu Angular request đến ```/assets/index.html```, sẽ xảy ra lỗi 404, bởi vì tên thực tế của file có thể là ```/assets/9834f200909a098a0a9a-index.html```. Hơn nữa ```/assets/index.html``` hoạt động ở Rails 3 nhưng Rails 4 thì không.

Angular caches các template sau khi nó request chúng lần đầu, ta cần phải pre-populate cache đó trước. Bằng cách này, Angular sẽ không cần request bất kỳ asset nào.

Gem ```angular-rails-templates``` được tạo ra để làm điều đó.

Thêm vào Gemfile ```gem 'angular-rails-templates'``` và ```bundle install```

Tương tự add vào ```Bowerfile``` ```asset 'angular-route'``` và chạy ```rake bower:install```

Thêm vào ```app/assets/javascripts/application.js```
```
//= require angular-route/angular-route
//= require angular-rails-templates
```

Thêm vào ```app/views/home/index.html.erb``` đoạn markup để "boot" Angular mỗi lần view được tạo bở Rails.
```ruby
<div ng-app="hbc">
  <div class="view-container">
    <div ng-view class="view-frame animate-view"></div>
  </div>
</div>
```

Sử dụng ```ng-app``` để Angular biết ứng dụng nào sẽ được load và ```ng-view``` để biết nơi nào để render view.

## Sử dụng coffee để viết controller ```app/assets/javascripts/app.coffee```
```
hbc = angular.module('hbc',[
  'templates',
  'ngRoute',
  'controllers',
])

hbc.config([ '$routeProvider',
  ($routeProvider)->
    $routeProvider
      .when('/',
        templateUrl: "index.html"
        controller: 'RecipesController'
      )
])

controllers = angular.module('controllers',[])
controllers.controller("RecipesController", [ '$scope',
  ($scope)->
])
```


Cuối cùng là tạo ```index.html```. Mặc định ```angular-rails-templates``` sẽ tìm templates ở ```app/assets/javascripts/templates```


Controller ở trên phục vụ 2 mục đích. Phản hồi lại nút "Search" và trả về kết quả.
Vì chưa có backend nên ta sẽ xây dựng controller và view bên cạnh Angular filter.
Controller tìm một url parameter "keywords", nếu tồn tại, trả về kết quả search.

```
app/assets/javascripts/app.coffee

hbc = angular.module('hbc',[
  'templates',
  'ngRoute',
  'controllers',
])

hbc.config([ '$routeProvider',
  ($routeProvider)->
    $routeProvider
      .when('/',
        templateUrl: "index.html"
        controller: 'RecipesController'
      )
])

recipes = [
  {
    id: 1
    name: 'Baked Potato w/ Cheese'
  },
  {
    id: 2
    name: 'Garlic Mashed Potatoes',
  },
  {
    id: 3
    name: 'Potatoes Au Gratin',
  },
  {
    id: 4
    name: 'Baked Brussel Sprouts',
  },
]
controllers = angular.module('controllers',[])
controllers.controller("RecipesController", [ '$scope', '$routeParams', '$location',
  ($scope,$routeParams,$location)->
    $scope.search = (keywords)->  $location.path("/").search('keywords',keywords)

    if $routeParams.keywords
      keywords = $routeParams.keywords.toLowerCase()
      $scope.recipes = recipes.filter (recipe)-> recipe.name.toLowerCase().indexOf(keywords) != -1
    else
      $scope.recipes = []
])
```

## View

```html
app/assets/javascripts/templates/index.html
<header class="row">
  <h1 class="text-center col-md-6 col-md-offset-3">Find Recipes</h1>
</header>
<section class="row">
  <form>
    <div class="form-group col-md-6 col-md-offset-3">
      <label for="keywords" class="sr-only">Keywords</label>
      <input ng-model="keywords" name="keywords" type="text" autofocus class="form-control" placeholder="Recipe name, e.g. Baked Potato">
    </div>
    <div class="form-group col-md-6 col-md-offset-3 text-center">
      <button ng-click="search(keywords)" class="btn btn-primary btn-lg">Search</button>
    </div>
  </form>
</section>
<hr>
<section class="row" ng-if="recipes">
  <h1 class="text-center h2">Results</h1>
  <ul class="list-unstyled">
    <li ng-repeat="recipe in recipes">
      <section class="well col-md-6 col-md-offset-3">
        <h1 class="h3 col-md-6 text-right" style="margin-top: 0"><a href="#">{{recipe.name}}</a></h1>
        <div class="col-md-6">
          <button class="btn btn-info">Edit</button>
          <button class="btn btn-danger">Delete</button>
        </div>
      </section>
    </li>
  </ul>
</section>
```

## Demo
Search recipes

https://hbcnt.herokuapp.com

# Kết luận

Sử dụng Angular thay vì cách mặc định của Rails khá khó để tạo một ứng dụng CRUD. Tuy nhiên nó cho chúng ta cái nhìn cơ bản về Angular cũng như sử dụng Bower để cung cấp các thư viện không có sẵn khác.

