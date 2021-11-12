import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sourceName", "sourceReference" ]

  validateSource() {
    if(this.sourceNameTarget.value.length == 0 && this.sourceReferenceTarget.value.length > 0) {
      this.sourceNameTarget.setCustomValidity("Source name is required for source reference");
    } else {
      this.sourceNameTarget.setCustomValidity("");
    }
  }
}
