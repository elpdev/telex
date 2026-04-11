import { Controller } from "@hotwired/stimulus"

// Rewrites <time datetime="..."> elements (rendered by the mono_timestamp
// helper in app/helpers/design_helper.rb) into the browser's local timezone.
// The server-rendered text remains as a progressive-enhancement fallback for
// no-JS users and during the brief hydration window.
const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

const pad2 = (n) => String(n).padStart(2, "0")

export default class extends Controller {
  connect() {
    const iso = this.element.getAttribute("datetime")
    if (!iso) return

    const date = new Date(iso)
    if (isNaN(date.getTime())) return

    const formatted = this.formatTimestamp(date, new Date())
    if (formatted != null) this.element.textContent = formatted
  }

  // Mirrors app/helpers/design_helper.rb#mono_timestamp in the browser's
  // local timezone:
  //   - same local calendar day  -> "HH:MM"   (24-hour, zero-padded)
  //   - same local calendar year -> "MON DD"  (e.g. "JAN 05")
  //   - older                    -> "YYYY-MM-DD"
  formatTimestamp(date, now) {
    const sameDay =
      date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate()

    if (sameDay) {
      return `${pad2(date.getHours())}:${pad2(date.getMinutes())}`
    }

    if (date.getFullYear() === now.getFullYear()) {
      return `${MONTHS[date.getMonth()]} ${pad2(date.getDate())}`
    }

    return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
  }
}
