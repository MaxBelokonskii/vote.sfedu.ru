# Rack::Attack — rate limiting and brute-force protection.
# Protects authentication endpoints and the API from abuse.
#
# Requests are keyed by IP. In production behind nginx, ensure nginx
# sets X-Forwarded-For and configure:
#   config.middleware.insert_before Rack::Attack, ... (if needed)
class Rack::Attack
  ### Throttle: Devise login endpoint ###
  # Max 5 failed login attempts per 20 seconds per IP.
  throttle("sign_in/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/sign_in" && req.post?
  end

  # Max 20 login attempts per 5 minutes per IP.
  throttle("sign_in/ip/extended", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/sign_in" && req.post?
  end

  ### Throttle: API endpoints ###
  # 60 requests per minute per IP for all API calls.
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  ### Throttle: General requests ###
  # 300 requests per minute per IP for all requests.
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets/", "/vite-dev/")
  end

  ### Block: Repeated login failures by email ###
  # Track failed Devise logins and block IPs after 10 failures per hour.
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
