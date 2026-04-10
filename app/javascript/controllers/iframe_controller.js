import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { messageId: Number }

  connect() {
    this.handleMessage = this.handleMessage.bind(this)
    window.addEventListener("message", this.handleMessage)
  }

  disconnect() {
    window.removeEventListener("message", this.handleMessage)
  }

  load() {
    this.element.style.height = `${this.minimumHeight}px`
  }

  handleMessage(event) {
    if (event.data?.type !== "message-body:resize") return
    if (Number(event.data.messageId) !== this.messageIdValue) return

    const height = Number(event.data.height)
    if (!Number.isFinite(height)) return

    this.element.style.height = `${Math.max(height, this.minimumHeight)}px`
  }

  get minimumHeight() {
    return 512
  }
}
