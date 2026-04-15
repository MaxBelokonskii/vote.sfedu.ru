class ApplicationController < ActionController::Base
  respond_to :html

  protect_from_forgery with: :exception
  before_action :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:identity_url, :identity_name])
  end

  def current_kind
    current_user&.kind
  end

  rescue_from CanCan::AccessDenied do |exception|
    logger.info "[CanCan::AccessDenied] #{exception.message}"
    render "errors/access_denied", layout: "application", locals: {message: exception.message}
  end

  rescue_from Savon::HTTPError do |exception|
    logger.error "[Savon::HTTPError] #{exception.message}"
    render "errors/coffee_break", layout: "application", locals: {message: exception.message}
  end
end
