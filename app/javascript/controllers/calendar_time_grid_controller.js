import { Controller } from "@hotwired/stimulus";

const REMS_PER_HOUR = 4;
const MIN_HEIGHT_REMS = 1.5;

export default class extends Controller {
  static targets = ["segment", "timeRange"];

  connect() {
    this.layout = this.layout.bind(this);
    this.layout();
    window.addEventListener("resize", this.layout);
  }

  disconnect() {
    window.removeEventListener("resize", this.layout);
  }

  layout() {
    this.segmentTargets.forEach((segment) => {
      const startAt = new Date(segment.dataset.startAt);
      const endAt = new Date(segment.dataset.endAt);
      if (Number.isNaN(startAt.getTime()) || Number.isNaN(endAt.getTime())) return;

      const startMinutes = startAt.getHours() * 60 + startAt.getMinutes();
      const durationMinutes = Math.max((endAt.getTime() - startAt.getTime()) / 60000, 30);
      const top = (startMinutes / 60) * REMS_PER_HOUR;
      const height = Math.max((durationMinutes / 60) * REMS_PER_HOUR, MIN_HEIGHT_REMS);
      const lane = Number(segment.dataset.lane || 0);
      const laneCount = Math.max(Number(segment.dataset.laneCount || 1), 1);
      const width = 100 / laneCount;
      const left = width * lane;

      segment.style.top = `${top.toFixed(3)}rem`;
      segment.style.height = `${height.toFixed(3)}rem`;
      segment.style.left = `${left.toFixed(3)}%`;
      segment.style.width = `${width.toFixed(3)}%`;

      const timeRange = segment.querySelector('[data-calendar-time-grid-target="timeRange"]');
      if (timeRange) {
        timeRange.textContent = `${this.formatTime(startAt)} - ${this.formatTime(endAt)}`;
      }
    });
  }

  formatTime(date) {
    return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
  }
}
