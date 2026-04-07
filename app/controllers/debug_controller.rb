class DebugController < ApplicationController
  before_action :ensure_non_production

  def login_as
    sign_in(User.find_by_email(params[:email])) if ENV["DEBUG_LOGIN_INTO_ACCOUNT"]
    redirect_to :root
  end

  private

  def ensure_non_production
    head :not_found if Rails.env.production?
  end
end
