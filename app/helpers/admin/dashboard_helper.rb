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

  def participation_chart_data(trend)
    labels = trend.map { |p| p[:date].strftime("%d.%m") }
    values = trend.map { |p| p[:count] }
    {
      data: {
        labels: labels,
        datasets: [{
          label: "Участий",
          data: values,
          borderColor: "#1565C0",
          backgroundColor: "rgba(21, 101, 192, 0.1)",
          fill: true,
          tension: 0.3,
          pointRadius: 2,
          pointHoverRadius: 5
        }]
      },
      options: {
        plugins: {legend: {display: false}},
        scales: {
          y: {beginAtZero: true, ticks: {precision: 0}},
          x: {ticks: {maxRotation: 0, autoSkip: true, maxTicksLimit: 10}}
        }
      },
      total: values.sum
    }
  end

  def teacher_kinds_chart_data(kinds)
    labels = ["Общий", "Физкультура", "Иностранный язык"]
    values = [kinds[:common], kinds[:physical_education], kinds[:foreign_language]]
    {
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: ["#1565C0", "#FFB300", "#4CAF50"],
          borderWidth: 2,
          borderColor: "#FFFFFF"
        }]
      },
      options: {
        plugins: {legend: {position: "bottom", labels: {padding: 12, font: {size: 12}}}},
        cutout: "60%"
      },
      total: values.sum
    }
  end
end
