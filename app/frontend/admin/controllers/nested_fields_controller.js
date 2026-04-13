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
    event.preventDefault()
    const entry = event.target.closest("[data-nested-fields-entry]")
    if (!entry) return

    const destroyInput = entry.querySelector("input[name*='_destroy']")
    if (destroyInput) {
      // Persisted record: mark for destruction, hide
      destroyInput.value = "1"
      entry.classList.add("hidden")
    } else {
      // New record: just remove from DOM
      entry.remove()
    }
  }
}
