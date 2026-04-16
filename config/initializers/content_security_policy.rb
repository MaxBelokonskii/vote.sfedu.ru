# Content Security Policy (CSP) — mitigates XSS attacks by restricting
# the sources from which scripts, styles, images etc. can be loaded.
#
# Adjust directives if you add third-party fonts, analytics, or CDN assets.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :data
    policy.img_src :self, :data, "https:"
    # 'unsafe-inline' for styles is needed by Tailwind JIT / Vuetify.
    policy.style_src :self, :unsafe_inline
    # Scripts: 'unsafe-eval' is required because Vue.js compiles in-DOM
    # templates at runtime (common.js mounts on #common-app with HTML content).
    policy.script_src :self, :unsafe_eval
    policy.connect_src :self
    policy.object_src :none
    policy.base_uri :self
    policy.frame_src :none
  end

  # Generate a nonce for inline scripts if needed in the future.
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w[script-src]

  # Report CSP violations instead of blocking them during initial rollout.
  # Switch to true once you have verified no legitimate resources are blocked.
  config.content_security_policy_report_only = false
end
