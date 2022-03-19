import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "copySource", "checkIcon", "copyIcon" ]

  copy() {
    navigator.clipboard.writeText(this.copySourceTarget.innerText);
    this.copyIconTarget.style.display = "none";
    this.checkIconTarget.style.display = "block";
    setTimeout(() => {
      this.copyIconTarget.style.display = "block";
      this.checkIconTarget.style.display = "none";
    }, 2000);
  }
}
