import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["autosaveField", "status"]
  static values = {
    delay: { type: Number, default: 1200 },
    url: String
  }

  connect() {
    this.abortController = null
    this.timeout = null
    this.formChanged = false

    this.boundQueueSave = this.queueSave.bind(this)
    this.boundQueueImmediateSave = this.queueImmediateSave.bind(this)
    this.boundBeforeUnload = this.beforeUnload.bind(this)
    this.boundSubmitStart = this.submitStart.bind(this)

    this.element.addEventListener("input", this.boundQueueSave)
    this.element.addEventListener("change", this.boundQueueImmediateSave)
    this.element.addEventListener("trix-change", this.boundQueueSave)
    this.element.addEventListener("turbo:submit-start", this.boundSubmitStart)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }

  disconnect() {
    this.element.removeEventListener("input", this.boundQueueSave)
    this.element.removeEventListener("change", this.boundQueueImmediateSave)
    this.element.removeEventListener("trix-change", this.boundQueueSave)
    this.element.removeEventListener("turbo:submit-start", this.boundSubmitStart)
    window.removeEventListener("beforeunload", this.boundBeforeUnload)

    window.clearTimeout(this.timeout)
    this.abortController?.abort()
  }

  queueSave(event) {
    if (this.ignoredEvent(event)) return

    this.formChanged = true
    this.setStatus("Saving...")
    window.clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => this.save(), this.delayValue)
  }

  queueImmediateSave(event) {
    if (this.ignoredEvent(event)) return

    this.formChanged = true
    this.setStatus("Saving...")
    window.clearTimeout(this.timeout)
    this.timeout = window.setTimeout(() => this.save(), 150)
  }

  submitStart(event) {
    if (event.target !== this.element) return

    window.clearTimeout(this.timeout)
    this.abortController?.abort()
    this.autosaveFieldTarget.value = "0"
  }

  beforeUnload() {
    if (!this.formChanged) return

    this.save({ keepalive: true })
  }

  async save(options = {}) {
    if (!this.formChanged) return

    this.abortController?.abort()
    this.abortController = new AbortController()
    this.autosaveFieldTarget.value = "1"

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        body: new FormData(this.element),
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
        },
        credentials: "same-origin",
        signal: this.abortController.signal,
        keepalive: options.keepalive === true
      })

      if (!response.ok) {
        this.setStatus("Autosave failed")
        return
      }

      this.formChanged = false
      this.setStatus("Saved just now")
    } catch (error) {
      if (error.name !== "AbortError") {
        this.setStatus("Autosave failed")
      }
    } finally {
      this.autosaveFieldTarget.value = "0"
    }
  }

  ignoredEvent(event) {
    return event.target.name === "autosave" || event.target.type === "submit"
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
