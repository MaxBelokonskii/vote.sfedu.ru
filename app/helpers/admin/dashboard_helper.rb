module Admin::DashboardHelper
  def dashboard_progress_color(coverage)
    case coverage
    when 0...30 then "bg-red-500"
    when 30...70 then "bg-amber-500"
    else "bg-emerald-500"
    end
  end

  def dashboard_check_classes(level, count)
    return "bg-emerald-50 border-emerald-200 text-emerald-800" if count.zero?

    case level
    when :critical then "bg-red-50 border-red-200 text-red-800"
    else "bg-amber-50 border-amber-200 text-amber-800"
    end
  end

  def dashboard_check_icon(count)
    count.zero? ? "✓" : "!"
  end
end
