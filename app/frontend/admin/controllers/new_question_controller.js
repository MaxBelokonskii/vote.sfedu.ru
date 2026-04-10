import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]
  static values = { index: { type: Number, default: 0 } }

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.indexValue++
  }

  remove(event) {
    event.target.closest("[data-new-question-target='entry']").remove()
  }
}
