# https://github.com/CareerFoundry/heroku-buildpack-nginx-pagespeed#existing-app

workers Integer(ENV["WEB_CONCURRENCY"] || 3)
threads_count = Integer(ENV["RAILS_MAX_THREADS"] || 5)
threads threads_count, threads_count
# https://github.com/puma/puma/blob/master/lib/puma/dsl.rb#L515
silence_single_worker_warning

rackup DefaultRackup
environment ENV["RACK_ENV"] || "development"

preload_app!

on_worker_fork do
  FileUtils.touch("/tmp/app-initialized")
end

if ENV.fetch("RAILS_ENV") == "production"
  bind "unix:///tmp/nginx.socket"
end
