import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "notice" ]

  static values = {
    lastUpdate: String,
    targetSelector: String,
  }

  initialize() {
    if (this.hasLastUpdateValue && this.hasTargetSelectorValue) {
      // Safari doesn't like dashes in dates 🙄
      const thisLastUpdate = new Date(this.lastUpdateValue.replace(/-/g, "/"));
      const pageLastUpdate = new Date(document.querySelector(this.targetSelectorValue).dataset.lastUpdate.replace(/-/g, "/"));
      if (thisLastUpdate > pageLastUpdate) {
        this.noticeTarget.style.display = "block";
      } else {
        console.log("Page outdated notice not initialized due to time difference.");
      }
    } else {
      console.log("Page outdated notice not initialized due to missing values.");
    }
  }

  refresh() {
    Turbo.visit(window.location);
  }

  close() {
    this.noticeTarget.parentNode.removeChild(this.noticeTarget);
  }
}
