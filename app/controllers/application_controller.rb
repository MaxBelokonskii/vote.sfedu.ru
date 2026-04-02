class ApplicationController < ActionController::Base
  respond_to :html

  protect_from_forgery with: :exception
  before_action :update_sanitized_params, if: :devise_controller?
  # before_action :set_sentry_context

  def update_sanitized_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:identity_url, :identity_name])
  end

  def current_kind
    current_user&.kind
  end

  rescue_from CanCan::AccessDenied do |exception|
    Sentry.capture_message(exception.message,
      level: "info",
      fingerprint: ["cancancan"])
    render "errors/access_denied", layout: "application", locals: {message: exception.message}
  end

  rescue_from Savon::HTTPError do |exception|
    Sentry.capture_message(exception.message,
      level: "info",
      fingerprint: ["savon", "soap"])
    render "errors/coffee_break", layout: "application", locals: {message: exception.message}
  end

  private

  def set_sentry_context
    Sentry.set_user(id: current_user&.id, external_id: current_kind&.external_id)
    Sentry.set_extras(params: params.to_unsafe_h, url: request.url)
  end
end
