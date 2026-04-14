class Admin::DashboardController < Admin::BaseController
  def show
    authorize!(:index, :admin)
    @metrics = Admin::DashboardMetrics.call
  end
end
