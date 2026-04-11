import { Controller } from "@hotwired/stimulus"

// Flyout :: slide-out panels anchored to the left rail.
// Two panels: mbx (mailboxes/channels) and lbl (labels). Opening one
// closes the other. Esc + outside-click both dismiss.
export default class extends Controller {
  static targets = ["mbxPanel", "lblPanel", "mbxFilter", "mbxGroup"]

  connect() {
    this.boundKey = this.handleKey.bind(this)
    this.boundClick = this.handleDocumentClick.bind(this)
    document.addEventListener("keydown", this.boundKey)
    document.addEventListener("mousedown", this.boundClick)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKey)
    document.removeEventListener("mousedown", this.boundClick)
  }

  toggleMbx(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const willOpen = this.mbxPanelTarget.classList.contains("hidden")
    this.hideAll()
    if (willOpen) this.show(this.mbxPanelTarget)
  }

  toggleLbl(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const willOpen = this.lblPanelTarget.classList.contains("hidden")
    this.hideAll()
    if (willOpen) this.show(this.lblPanelTarget)
  }

  close() {
    this.hideAll()
  }

  handleKey(event) {
    if (event.key === "Escape" && this.anyOpen()) {
      event.preventDefault()
      this.hideAll()
    }
  }

  handleDocumentClick(event) {
    if (!this.anyOpen()) return
    // If the click is inside any flyout panel or on the rail itself, ignore.
    const insideFlyout = this.hasMbxPanelTarget && this.mbxPanelTarget.contains(event.target)
    const insideLbl = this.hasLblPanelTarget && this.lblPanelTarget.contains(event.target)
    const insideRail = event.target.closest("[data-flyout-rail]")
    if (insideFlyout || insideLbl || insideRail) return
    this.hideAll()
  }

  show(panel) {
    panel.classList.remove("hidden")
    panel.classList.add("flex")
    const input = panel.querySelector("[data-flyout-autofocus]")
    if (panel === this.mbxPanelTarget) this.resetMailboxFilter()
    if (input) requestAnimationFrame(() => input.focus())
  }

  hideAll() {
    [this.hasMbxPanelTarget && this.mbxPanelTarget, this.hasLblPanelTarget && this.lblPanelTarget]
      .filter(Boolean)
      .forEach((p) => {
        p.classList.add("hidden")
        p.classList.remove("flex")
      })
  }

  anyOpen() {
    return (this.hasMbxPanelTarget && !this.mbxPanelTarget.classList.contains("hidden")) ||
           (this.hasLblPanelTarget && !this.lblPanelTarget.classList.contains("hidden"))
  }

  filterMailboxes() {
    if (!this.hasMbxFilterTarget) return

    const query = this.mbxFilterTarget.value.trim().toLowerCase()

    this.mbxGroupTargets.forEach((group) => {
      const haystack = group.dataset.searchText || ""
      group.classList.toggle("hidden", query.length > 0 && !haystack.includes(query))
    })
  }

  resetMailboxFilter() {
    if (!this.hasMbxFilterTarget) return

    this.mbxFilterTarget.value = ""
    this.filterMailboxes()
  }
}
