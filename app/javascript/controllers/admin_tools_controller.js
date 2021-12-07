import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "adminToolsBar" ]

  connect() {
    if (localStorage.getItem("hideAdminTools")) {
      this.close();
    }
  }

  close() {
    this.adminToolsBarTarget.parentNode.removeChild(this.adminToolsBarTarget);
    localStorage.setItem("hideAdminTools", "true");
  }
}
