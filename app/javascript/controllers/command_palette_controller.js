import { Controller } from "@hotwired/stimulus"

// Command palette :: Cmd+K overlay driven by the keyboard controller.
// Filters suggestions as you type, navigates with up/down, selects with Enter.
export default class extends Controller {
  static targets = ["overlay", "dialog", "input", "list", "item", "empty", "breadcrumb"]
  static values = { searchTemplate: String, tree: String }

  connect() {
    this.tree = JSON.parse(this.treeValue || "[]")
    this.stack = []
    this.index = 0
    this.boundKey = this.handleGlobalKey.bind(this)
    document.addEventListener("keydown", this.boundKey)
    this.renderCurrentLevel()
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
    this.stack = []
    this.index = 0
    this.renderCurrentLevel()
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
    this.stack = []
    this.inputTarget.value = ""
    this.renderCurrentLevel()
  }

  backdropClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  filter() {
    const query = this.inputTarget.value.trim()
    this.removeSearchItems()

    const normalizedQuery = query.toLowerCase()
    let visibleCount = 0
    this.itemTargets.forEach((item) => {
      const label = (item.dataset.label || "").toLowerCase()
      const match = normalizedQuery === "" || label.includes(normalizedQuery)
      item.classList.toggle("hidden", !match)
      if (match) visibleCount += 1
    })

    if (this.shouldShowSearchAction(query, visibleCount)) {
      this.insertSearchAction(query)
      visibleCount += 1
    }

    this.index = 0
    this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    this.refreshHighlight()
  }

  navigate(event) {
    if (event.key === "ArrowLeft") {
      event.preventDefault()
      this.stepBack()
      return
    }

    if (event.key === "Backspace" && this.inputTarget.value === "") {
      event.preventDefault()
      this.stepBack()
      return
    }

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
      const control = visible[this.index].querySelector("a, button")
      if (control) control.click()
    }
  }

  select(event) {
    const item = event.currentTarget.closest('li[data-command-palette-target~="item"]')
    if (!item) return

    const kind = item.dataset.kind
    if (kind === "back") {
      this.stepBack()
      return
    }

    if (kind === "search") {
      this.close()
      return
    }

    if (kind === "node") {
      this.stack.push(item.dataset.nodeId)
      this.inputTarget.value = ""
      this.index = 0
      this.renderCurrentLevel()
      return
    }

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

  renderCurrentLevel() {
    this.renderItems()
    this.updateBreadcrumb()
    this.filter()
  }

  renderItems() {
    this.listTarget.innerHTML = ""

    const items = []
    if (this.stack.length > 0) items.push(this.buildBackItem())

    this.currentNodes().forEach((node) => {
      items.push(this.buildNodeItem(node))
    })

    items.push(this.buildEmptyItem())
    items.forEach((item) => this.listTarget.appendChild(item))
  }

  buildBackItem() {
    return this.buildItem({ kind: "back", label: "back", hint: "UP" })
  }

  buildNodeItem(node) {
    const isLeaf = !node.children || node.children.length === 0
    return this.buildItem({
      kind: isLeaf ? "action" : "node",
      label: node.label,
      hint: node.hint,
      nodeId: node.id,
      href: node.href,
      method: node.method
    })
  }

  buildItem({ kind, label, hint, nodeId = "", href = "", method = "get" }) {
    const item = document.createElement("li")
    item.dataset.commandPaletteTarget = "item"
    item.dataset.kind = kind
    item.dataset.label = label
    item.dataset.hint = hint || ""
    if (nodeId) item.dataset.nodeId = nodeId
    if (href) item.dataset.href = href
    item.className = ""

    let control
    if (kind === "action" || kind === "search") {
      control = document.createElement("a")
      control.href = href
      control.dataset.turboMethod = method
    } else {
      control = document.createElement("button")
      control.type = "button"
    }

    control.className = "flex w-full items-center justify-between gap-4 px-4 py-2 text-left text-phosphor hover:bg-bg-3 hover:text-amber"
    control.dataset.action = "click->command-palette#select"

    const text = document.createElement("span")
    text.className = "flex items-center gap-2"

    const prompt = document.createElement("span")
    prompt.className = "text-phosphor-dim"
    prompt.textContent = ">"

    const labelNode = document.createElement("span")
    labelNode.textContent = label

    text.append(prompt, labelNode)

    const hintNode = document.createElement("span")
    hintNode.className = "text-[0.6rem] text-phosphor-faint"
    hintNode.textContent = hint || ""

    control.append(text, hintNode)
    item.appendChild(control)
    return item
  }

  buildEmptyItem() {
    const item = document.createElement("li")
    item.dataset.commandPaletteTarget = "empty"
    item.className = "hidden px-4 py-6 text-center text-phosphor-faint"
    item.textContent = "> no matches :: widen query _"
    return item
  }

  insertSearchAction(query) {
    const searchItem = this.buildItem({
      kind: "search",
      label: `search ${query}`,
      hint: "SEARCH",
      href: this.searchHrefFor(query)
    })
    this.listTarget.insertBefore(searchItem, this.emptyTarget)
  }

  removeSearchItems() {
    this.itemTargets
      .filter((item) => item.dataset.kind === "search")
      .forEach((item) => item.remove())
  }

  shouldShowSearchAction(query, visibleCount) {
    return query !== "" && this.stack.length === 0 && visibleCount === 0
  }

  updateBreadcrumb() {
    const labels = this.currentPathNodes().map((node) => node.label.toUpperCase())
    this.breadcrumbTarget.textContent = labels.length === 0 ? "ROOT" : labels.join(" > ")
  }

  currentNodes() {
    if (this.stack.length === 0) return this.tree

    const parent = this.currentPathNodes().at(-1)
    return parent?.children || []
  }

  currentPathNodes() {
    const path = []
    let nodes = this.tree

    this.stack.forEach((id) => {
      const node = nodes.find((entry) => entry.id === id)
      if (!node) return
      path.push(node)
      nodes = node.children || []
    })

    return path
  }

  stepBack() {
    if (this.stack.length === 0) return

    this.stack.pop()
    this.inputTarget.value = ""
    this.index = 0
    this.renderCurrentLevel()
  }

  searchHrefFor(query) {
    return this.searchTemplateValue.replaceAll("COMMAND_PALETTE_QUERY", encodeURIComponent(query))
  }
}
