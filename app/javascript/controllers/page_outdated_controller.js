import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "notice" ]

  static values = {
    lastUpdate: String,
    targetSelector: String,
  }

  initialize() {
    if (this.hasLastUpdateValue && this.hasTargetSelectorValue && document.querySelector(this.targetSelectorValue)) {
      setTimeout(() => {
        // Safari doesn't like dashes in dates 🙄
        const thisLastUpdate = new Date(this.lastUpdateValue.replace(/-/g, "/"));
        const pageLastUpdate = new Date(document.querySelector(this.targetSelectorValue).dataset.lastUpdate.replace(/-/g, "/"));
        if (thisLastUpdate > pageLastUpdate) {
          this.noticeTarget.style.display = "block";
        } else {
          // console.log("Page outdated notice not initialized due to time difference.");
        }
      }, 500);
    } else {
      // We can hit this path if the data just hasn't been set, or if the item
      // to check the time on is no longer on the page. In these cases it's just
      // a no-op.
      // console.log("Page outdated notice not initialized due to missing values.");
    }
  }

  refresh() {
    Turbo.visit(window.location);
  }

  close() {
    this.noticeTarget.parentNode.removeChild(this.noticeTarget);
  }
}
