import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "notice" ]

  refresh() {
    Turbo.visit(window.location);
  }

  close() {
    this.noticeTarget.parentNode.removeChild(this.noticeTarget);
  }
}
