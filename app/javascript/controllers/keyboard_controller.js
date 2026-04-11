import { Controller } from "@hotwired/stimulus"

// Global keyboard shortcut dispatcher.
// - j/k: navigate message feed rows
// - c: compose (click .rail compose button)
// - r/a/f: reply / reply-all / forward
// - m: mark read/unread
// - *: star/unstar
// - e: archive selected message
// - #: trash selected message
// - J/B/D/T (shift): junk / block sender / block domain / trust sender
//   Triage actions require shift so they can't be triggered accidentally,
//   don't clobber `j` row navigation, and don't race the `g d` / `g t` chords.
// - g then i/s/d/a/t: jump to mailbox view
// - /: focus list search
// - ?: shortcut help overlay
//
// Action rail buttons are addressed by their data-shortcut attribute so the
// visible content can change (keycap icons) without breaking the dispatcher.
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
        // Row nav: lowercase only. Uppercase J is junk (see triage block below).
        event.preventDefault()
        this.moveRow(1)
        break
      case "k":
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
        this.clickShortcut("r")
        break
      case "a":
      case "A":
        event.preventDefault()
        this.clickShortcut("a")
        break
      case "f":
      case "F":
        event.preventDefault()
        this.clickShortcut("f")
        break
      case "e":
      case "E":
        event.preventDefault()
        this.clickShortcut("e")
        break
      case "#":
        event.preventDefault()
        this.clickShortcut("#")
        break
      case "m":
      case "M":
        event.preventDefault()
        this.clickShortcut("m")
        break
      case "*":
        event.preventDefault()
        this.clickShortcut("*")
        break
      // Triage actions require shift: uppercase keys don't conflict with
      // existing row nav (j) or the `g d`/`g t` chords, and make destructive
      // one-tap actions intentional rather than easy to fat-finger.
      case "J":
        event.preventDefault()
        this.clickShortcut("j")
        break
      case "B":
        event.preventDefault()
        this.clickShortcut("b")
        break
      case "D":
        event.preventDefault()
        this.clickShortcut("d")
        break
      case "T":
        event.preventDefault()
        this.clickShortcut("t")
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

  // Look up an action rail button by its data-shortcut attribute and click it.
  // The template only renders one button per shortcut letter at a time
  // (e.g. [star] OR [unstar], never both), so a plain attribute selector is
  // sufficient. Needs a quoted key because `#` and `*` are not bare CSS idents.
  clickShortcut(key) {
    const selector = `[data-thread-reader-target='actions'] [data-shortcut="${key}"]`
    const el = document.querySelector(selector)
    if (el) {
      el.click()
      return true
    }
    return false
  }

  clickFirstMatching(selector) {
    const el = document.querySelector(selector)
    if (el) el.click()
  }
}
