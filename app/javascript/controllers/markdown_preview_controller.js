import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.boundQueueRender = this.queueRender.bind(this)
    this.inputTarget.addEventListener("input", this.boundQueueRender)
  }

  disconnect() {
    this.inputTarget.removeEventListener("input", this.boundQueueRender)
    window.clearTimeout(this.timeout)
  }

  queueRender() {
    window.clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => this.renderPreview(), 250)
  }

  async renderPreview() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "text/html",
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
      },
      body: JSON.stringify({ body: this.inputTarget.value }),
      credentials: "same-origin"
    })

    if (!response.ok) return

    this.outputTarget.innerHTML = await response.text()
  }
}
