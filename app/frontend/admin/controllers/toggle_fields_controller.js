import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  toggle(event) {
    const checked = event.target.checked
    this.containerTarget.classList.toggle("hidden", !checked)
    this.containerTarget.querySelectorAll("input, select").forEach((input) => {
      input.disabled = !checked
    })
  }
}
