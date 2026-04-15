# Protective HTTP security headers for all responses.
# These headers are set regardless of SSL configuration.
Rails.application.config.action_dispatch.default_headers.merge!(
  # Prevent the page from being rendered inside an iframe (clickjacking).
  "X-Frame-Options" => "DENY",
  # Prevent browsers from guessing MIME types (MIME-sniffing attacks).
  "X-Content-Type-Options" => "nosniff",
  # Legacy XSS filter (still respected by older browsers).
  "X-XSS-Protection" => "1; mode=block",
  # Control how much referrer info is sent in cross-origin requests.
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  # Disable browser features that are not needed by this application.
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=()"
)
