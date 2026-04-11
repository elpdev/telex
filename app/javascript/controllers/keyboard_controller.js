import { Controller } from "@hotwired/stimulus"

// Global keyboard shortcut dispatcher.
// - j/k: navigate message feed rows
// - c: compose (click .rail compose button)
// - r/a/f: reply / reply-all / forward (click the thread header buttons)
// - e: archive selected message
// - #: trash selected message
// - m: mark read/unread
// - g then i/s/d/a/t: jump to mailbox view
// - /: focus list search
// - ?: shortcut help overlay (TODO)
// Shortcuts do NOT fire when typing in inputs/textareas/contenteditable.
export default class extends Controller {
  connect() {
    this.pending = null
    this.pendingTimer = null
    this.boundKey = this.handleKey.bind(this)
    document.addEventListener("keydown", this.boundKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKey)
  }

  handleKey(event) {
    if (this.shouldIgnore(event)) return
    const key = event.key

    // Handle 'g' chord (go to ...)
    if (this.pending === "g") {
      this.clearPending()
      const map = { i: "inbox", s: "sent", d: "drafts", a: "archived", t: "trash" }
      const mb = map[key.toLowerCase()]
      if (mb) {
        event.preventDefault()
        const params = new URLSearchParams({ mailbox: mb })
        Turbo.visit(`/?${params.toString()}`)
      }
      return
    }

    if (key === "g") {
      this.pending = "g"
      this.pendingTimer = setTimeout(() => this.clearPending(), 900)
      return
    }

    if (event.metaKey || event.ctrlKey || event.altKey) return

    const row = this.selectedRow()
    switch (key) {
      case "j":
      case "J":
        event.preventDefault()
        this.moveRow(1)
        break
      case "k":
      case "K":
        event.preventDefault()
        this.moveRow(-1)
        break
      case "/":
        event.preventDefault()
        this.focusFilter()
        break
      case "?":
        event.preventDefault()
        this.showHelp()
        break
      case "c":
      case "C":
        event.preventDefault()
        this.clickFirstMatching("[data-shortcut='c']")
        break
      case "r":
      case "R":
        event.preventDefault()
        this.clickHeaderButton("reply")
        break
      case "a":
      case "A":
        event.preventDefault()
        this.clickHeaderButton("reply all")
        break
      case "f":
      case "F":
        event.preventDefault()
        this.clickHeaderButton("fwd")
        break
      case "e":
      case "E":
        event.preventDefault()
        this.clickHeaderButton("archive")
        break
      case "#":
        event.preventDefault()
        this.clickHeaderButton("trash")
        break
      case "m":
      case "M":
        event.preventDefault()
        this.clickHeaderButton("unread") || this.clickHeaderButton("read")
        break
      case "*":
        event.preventDefault()
        this.clickHeaderButton("star") || this.clickHeaderButton("unstar")
        break
    }
  }

  shouldIgnore(event) {
    const target = event.target
    if (!target) return false
    const tag = target.tagName
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true
    if (target.isContentEditable) return true
    return false
  }

  clearPending() {
    this.pending = null
    if (this.pendingTimer) {
      clearTimeout(this.pendingTimer)
      this.pendingTimer = null
    }
  }

  selectedRow() {
    return document.querySelector("[data-row-index].border-amber") ||
           document.querySelector("[data-row-index]")
  }

  moveRow(delta) {
    const rows = Array.from(document.querySelectorAll("[data-row-index]"))
    if (rows.length === 0) return
    const currentIdx = rows.findIndex((r) => r.classList.contains("border-amber"))
    let nextIdx = currentIdx + delta
    if (nextIdx < 0) nextIdx = 0
    if (nextIdx >= rows.length) nextIdx = rows.length - 1
    const next = rows[nextIdx]
    if (next) {
      next.scrollIntoView({ block: "nearest" })
      next.click()
    }
  }

  focusFilter() {
    const input = document.querySelector("[data-global-search]")
    if (input) input.focus()
  }

  showHelp() {
    const overlay = document.querySelector("[data-shortcut-help]")
    if (!overlay) return
    if (overlay.open) {
      overlay.close()
    } else {
      overlay.showModal()
    }
  }

  clickHeaderButton(needle) {
    const buttons = Array.from(document.querySelectorAll("[data-thread-reader-target='actions'] button"))
    const match = buttons.find((b) => b.textContent.toLowerCase().includes(needle))
    if (match) {
      match.click()
      return true
    }
    return false
  }

  clickFirstMatching(selector) {
    const el = document.querySelector(selector)
    if (el) el.click()
  }
}
