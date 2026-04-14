import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "text", "maxRating", "questionsList", "error"]

  toggle() {
    this.formTarget.classList.toggle("hidden")
    if (!this.formTarget.classList.contains("hidden")) {
      this.textTarget.focus()
    }
  }

  async submit(event) {
    event.preventDefault()
    this.clearError()

    const text = this.textTarget.value.trim()
    const maxRating = this.maxRatingTarget.value || 10

    if (!text) {
      this.showError("Введите текст вопроса")
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch("/admin/questions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json",
        },
        body: JSON.stringify({ question: { text, max_rating: maxRating } }),
      })

      if (!response.ok) {
        const data = await response.json()
        this.showError(data.errors?.join(", ") || "Ошибка при создании вопроса")
        return
      }

      const question = await response.json()
      this.addQuestionToList(question)
      this.resetForm()
    } catch {
      this.showError("Ошибка сети")
    }
  }

  addQuestionToList(question) {
    const label = document.createElement("label")
    label.className = "flex items-center gap-3 p-3 rounded-lg border border-primary bg-primary-50 cursor-pointer hover_bg-gray-50 transition-colors"

    const checkbox = document.createElement("input")
    checkbox.type = "checkbox"
    checkbox.name = "stage[question_ids][]"
    checkbox.value = question.id
    checkbox.checked = true
    checkbox.className = "rounded border-gray-300 text-primary focus_ring-primary"

    const textSpan = document.createElement("span")
    textSpan.className = "text-sm text-gray-700"
    textSpan.textContent = question.text

    const ratingSpan = document.createElement("span")
    ratingSpan.className = "text-xs text-gray-400 ml-auto"
    ratingSpan.textContent = `макс. ${question.max_rating}`

    label.append(checkbox, textSpan, ratingSpan)
    this.questionsListTarget.appendChild(label)
  }

  resetForm() {
    this.textTarget.value = ""
    this.maxRatingTarget.value = "10"
    this.formTarget.classList.add("hidden")
    this.clearError()
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
