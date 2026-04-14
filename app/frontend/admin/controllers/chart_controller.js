import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: { type: Object, default: {} },
  }

  connect() {
    this.chart = new Chart(this.element.getContext("2d"), {
      type: this.typeValue,
      data: this.dataValue,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        ...this.optionsValue,
      },
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
