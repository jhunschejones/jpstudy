release: rake db:migrate
web: rake reset_monthly_user_resource_limits && bin/start-nginx bundle exec puma -C config/puma.rb
