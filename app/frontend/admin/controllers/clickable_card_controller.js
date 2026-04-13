import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    // Don't navigate if user clicked an interactive element (link, button, input)
    if (event.target.closest("a, button, input, select, textarea, label, [data-clickable-card-ignore]")) {
      return
    }
    window.location.href = this.urlValue
  }
}
