# Little Shop | Final Project | Backend Starter Repo

# README

## Little Shop Project - Backend
Link to [backend](https://github.com/bwillett2003/little-shop-be-final-starter)

## Little Shop Project - Frontend
Link to [frontend](https://github.com/bwillett2003/little-shop-fe-final-starter)

### Contributors
* [Bryan Willet](https://github.com/bwillett2003)

**Ruby version:** 3.2.2

**Rails version:** 7.1.3.4

**System dependencies/gems:**
- postgresql version 14.13
- jsonapi-serializer
- simplecov
- rspec-rails
- should-matchers
- pry
- faker
- factory_bot_rails

**Configuration**
#### Database creation
- rails db:{drop,create}
- rails runner ActiveRecord::Tasks::DatabaseTasks.load_seed
- rails db:migrate

### How to run the test suite
- from the main project directory run: 'bundle exec rspec spec/models'
- from the main project directory run: 'bundle exec rspec spec/requests'

### Services (job queues, cache servers, search engines, etc.)

### Deployment instructions
- Clone project down to your computer
- cd into the project directory
- run 'bundle install'
- run rails d:{drop,create}
- rails runner ActiveRecord::Tasks::DatabaseTasks.load_seed
- rails db:migrate
- run your server with `rails s` and you should be able to access endpoints via localhost:3000.
