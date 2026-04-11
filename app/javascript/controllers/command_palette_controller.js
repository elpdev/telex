import { Controller } from "@hotwired/stimulus"

// Command palette :: Cmd+K overlay driven by the keyboard controller.
// Filters suggestions as you type, navigates with up/down, selects with Enter.
export default class extends Controller {
  static targets = ["overlay", "dialog", "input", "list", "item", "empty", "searchItem", "searchLink", "searchLabel"]
  static values = { searchTemplate: String }

  connect() {
    this.index = 0
    this.boundKey = this.handleGlobalKey.bind(this)
    document.addEventListener("keydown", this.boundKey)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKey)
  }

  handleGlobalKey(event) {
    const isMac = navigator.platform.toUpperCase().includes("MAC")
    const cmd = isMac ? event.metaKey : event.ctrlKey
    if (cmd && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.toggle()
    } else if (event.key === "Escape" && this.isOpen) {
      event.preventDefault()
      this.close()
    }
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
    this.isOpen = true
    requestAnimationFrame(() => {
      this.inputTarget.focus()
      this.inputTarget.select()
    })
    this.filter()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
    this.isOpen = false
    this.inputTarget.value = ""
    this.filter()
  }

  backdropClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  filter() {
    const query = this.inputTarget.value.trim()
    this.updateSearchAction(query)

    const normalizedQuery = query.toLowerCase()
    let visibleCount = 0
    this.itemTargets.forEach((item) => {
      const label = (item.dataset.label || "").toLowerCase()
      const match = normalizedQuery === "" || label.includes(normalizedQuery)
      item.classList.toggle("hidden", !match)
      if (match) visibleCount += 1
    })
    this.index = 0
    this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    this.refreshHighlight()
  }

  navigate(event) {
    const visible = this.visibleItems()
    if (visible.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.index = (this.index + 1) % visible.length
      this.refreshHighlight()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.index = (this.index - 1 + visible.length) % visible.length
      this.refreshHighlight()
    } else if (event.key === "Enter") {
      event.preventDefault()
      const link = visible[this.index].querySelector("a")
      if (link) link.click()
    }
  }

  select() {
    this.close()
  }

  visibleItems() {
    return this.itemTargets.filter((i) => !i.classList.contains("hidden"))
  }

  refreshHighlight() {
    const visible = this.visibleItems()
    visible.forEach((item, i) => {
      item.classList.toggle("bg-bg-3", i === this.index)
    })
    if (visible[this.index]) {
      visible[this.index].scrollIntoView({ block: "nearest" })
    }
  }

  updateSearchAction(query) {
    if (!this.hasSearchItemTarget || !this.hasSearchLinkTarget || !this.hasSearchLabelTarget) return

    if (query === "") {
      this.searchItemTarget.dataset.label = ""
      this.searchItemTarget.classList.add("hidden")
      this.searchLabelTarget.textContent = "search"
      this.searchLinkTarget.href = this.searchHrefFor("")
      return
    }

    const label = `search ${query}`
    this.searchItemTarget.dataset.label = label
    this.searchLabelTarget.textContent = label
    this.searchLinkTarget.href = this.searchHrefFor(query)
  }

  searchHrefFor(query) {
    return this.searchTemplateValue.replaceAll("COMMAND_PALETTE_QUERY", encodeURIComponent(query))
  }
}
