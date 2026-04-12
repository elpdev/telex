import { Controller } from "@hotwired/stimulus"

// Flyout :: slide-out panels anchored to the left rail.
// Two panels: mbx (mailboxes/channels) and lbl (labels). Opening one
// closes the other. Esc + outside-click both dismiss.
export default class extends Controller {
  static targets = ["appPanel", "mbxPanel", "lblPanel", "calPanel", "fldPanel"]

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

  toggleApp(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const willOpen = this.appPanelTarget.classList.contains("hidden")
    this.hideAll()
    if (willOpen) this.show(this.appPanelTarget)
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

  toggleCal(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const willOpen = this.calPanelTarget.classList.contains("hidden")
    this.hideAll()
    if (willOpen) this.show(this.calPanelTarget)
  }

  toggleFld(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const willOpen = this.fldPanelTarget.classList.contains("hidden")
    this.hideAll()
    if (willOpen) this.show(this.fldPanelTarget)
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
    const insidePanel = this.allPanels().some((p) => p.contains(event.target))
    const insideRail = event.target.closest("[data-flyout-rail]")
    if (insidePanel || insideRail) return
    this.hideAll()
  }

  show(panel) {
    panel.classList.remove("hidden")
    panel.classList.add("flex")
    const input = panel.querySelector("[data-flyout-autofocus]")
    if (input) requestAnimationFrame(() => input.focus())
  }

  hideAll() {
    this.allPanels().forEach((p) => {
      p.classList.add("hidden")
      p.classList.remove("flex")
    })
  }

  anyOpen() {
    return this.allPanels().some((p) => !p.classList.contains("hidden"))
  }

  allPanels() {
    return [
      this.hasAppPanelTarget && this.appPanelTarget,
      this.hasMbxPanelTarget && this.mbxPanelTarget,
      this.hasLblPanelTarget && this.lblPanelTarget,
      this.hasCalPanelTarget && this.calPanelTarget,
      this.hasFldPanelTarget && this.fldPanelTarget
    ].filter(Boolean)
  }
}
