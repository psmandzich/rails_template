# Gemfile extentions
gem 'rails-i18n'
gem 'haml-rails'
gem 'bootstrap-sass'
gem 'simple-navigation-bootstrap'
gem 'bootstrap_form'

gem_group :development do
  gem 'capistrano', '3.9.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
end

gem_group :development, :test do
  gem 'rspec-rails' # ,        '~> 3.5.0'
  gem 'factory_girl_rails' # , '~> 3.1.0'
  gem 'simplecov-rcov' # ,     '~> 0.2.3', :require => false
  gem 'simplecov' # ,          '~> 0.6.1', :require => false
  gem 'database_cleaner' # ,   '~> 0.7.2'
end

require 'rvm'

create_file '.ruby-version', RUBY_VERSION
create_file '.ruby-gemset', app_name

RVM.use_from_path! app_path

unless run 'bundle --version'
  run 'gem install bundler --no-rdoc --no-ri'
end

application do
  <<-RUBY
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :de
    config.i18n.available_locales = :de
  RUBY
end
run_bundle
generate 'rspec:install'

inject_into_file 'spec/rails_helper.rb', :after => "require 'rspec/rails'" do
  <<-RUBY
require 'support/factory_girl'
  RUBY
end

insert_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
  <<-RUBY
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include FactoryGirl::Syntax::Methods
  RUBY
end

gsub_file "spec/rails_helper.rb",
          "config.use_transactional_fixtures = true",
          "config.use_transactional_fixtures = false"

inject_into_file 'spec/spec_helper.rb', before: 'RSpec.configure' do
  <<-RUBY
require 'simplecov'
SimpleCov.start
  RUBY
end

create_file 'config/navigation.rb' do
  <<-RUBY
  SimpleNavigation::Configuration.run do |navigation|
    navigation.renderer = Bootstrap
      navigation.items do |primary|
  
    end
  end
  RUBY
end

remove_file 'app/views/layouts/*.erb'
create_file 'app/views/layouts/application.html.haml' do
  <<-RUBY
<!DOCTYPE html>
%html
  %head
    %title ProjectPlaner
    = csrf_meta_tags

    = stylesheet_link_tag    'application', media: 'all' 
    = javascript_include_tag 'application' 

  %body
    - if user_authenticated?
      %div.navbar-left
        %div.container-fluid
          = render_navigation :renderer => :bootstrap
    %div.container
      = yield
  RUBY
end

insert_into_file 'app/assets/javascripts/application.js', before: '//= require_tree .' do
  "//= require bootstrap\n"
end

remove_file 'app/assets/stylesheets/application.css'
create_file 'app/assets/stylesheets/application.scss' do
  <<-CSS
  @import 'rails_bootstrap_forms';
  @import "bootstrap-sprockets";
  @import "bootstrap";
  CSS
end

run 'cap install'

after_bundle do
  append_file '.gitignore', before: :end do
    <<-GIT
/.idea*
.DS_Store
/.bundle

config/database.yml
config/secrets.yml

/coverage

/log/*
!/log/.keep
/tmp
    GIT
  end

  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end