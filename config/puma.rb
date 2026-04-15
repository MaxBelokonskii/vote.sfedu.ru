workers Integer(ENV.fetch("WEB_CONCURRENCY", 2))
threads_count = Integer(ENV.fetch("MAX_THREADS", 2))
threads(threads_count, threads_count)

preload_app!

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "development")

# Allow up to 30 seconds for in-flight requests to complete before
# forcefully shutting down workers (zero-downtime rolling deploys).
force_shutdown_after ENV.fetch("PUMA_FORCE_SHUTDOWN_AFTER", 30)

on_worker_boot do
  ActiveRecord::Base.establish_connection
end

# Cleanly disconnect DB before worker exits to avoid connection leaks
# between rolling-deploy cycles.
on_worker_shutdown do
  ActiveRecord::Base.connection_pool.disconnect!
end

# Log worker lifecycle events to aid debugging during deploys.
on_worker_fork do
  # Invoked in the master process just before forking a new worker.
end

lowlevel_error_handler do |ex|
  # Allow Puma to handle the error gracefully rather than crashing.
  [500, {}, ["An unexpected error occurred: #{ex.message}"]]
end
