# Rack::Attack — rate limiting and brute-force protection.
# Protects authentication endpoints and the API from abuse.
#
# In production the app sits behind nginx in Docker Swarm. REMOTE_ADDR is
# always the nginx overlay-network IP, not the real client address.
# We use X-Forwarded-For (set by nginx via proxy_set_header) to identify
# the actual client. Rails must trust the nginx proxy for this to work —
# see `trusted_proxies` in config/application.rb.
class Rack::Attack
  # Resolve the real client IP from X-Forwarded-For when behind a trusted
  # proxy (nginx). Falls back to REMOTE_ADDR if the header is absent.
  def self.client_ip(req)
    req.env["action_dispatch.remote_ip"]&.to_s || req.ip
  end

  ### Throttle: Devise login endpoint ###
  # Max 5 login attempts per 20 seconds per real client IP.
  throttle("sign_in/ip", limit: 5, period: 20.seconds) do |req|
    client_ip(req) if req.path == "/sign_in" && req.post?
  end

  # Max 20 login attempts per 5 minutes per real client IP.
  throttle("sign_in/ip/extended", limit: 20, period: 5.minutes) do |req|
    client_ip(req) if req.path == "/sign_in" && req.post?
  end

  ### Throttle: API endpoints ###
  # 60 requests per minute per real client IP for all API calls.
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    client_ip(req) if req.path.start_with?("/api/")
  end

  ### Throttle: General requests ###
  # 300 requests per minute per real client IP.
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    client_ip(req) unless req.path.start_with?("/assets/", "/vite-dev/")
  end

  ### Block: Repeated login failures by email ###
  # Track failed Devise logins and block email addresses after 10 failures/hour.
  throttle("sign_in/email", limit: 10, period: 1.hour) do |req|
    if req.path == "/sign_in" && req.post?
      req.params["user"]&.dig("email")&.downcase&.gsub(/\s+/, "")
    end
  end

  ### Response for throttled requests ###
  # Return 429 with a Retry-After header so clients know when to retry.
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = (match_data[:period] - (now % match_data[:period])).to_s

    [
      429,
      {"Content-Type" => "application/json", "Retry-After" => retry_after},
      [{"error" => "Слишком много запросов. Попробуйте позже.", "retry_after" => retry_after}.to_json]
    ]
  end
end
