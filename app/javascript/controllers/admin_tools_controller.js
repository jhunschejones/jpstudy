import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "adminToolsBar" ]

  connect() {
    if (localStorage.getItem("hideAdminTools")) {
      return this.close();
    }
    this.adminToolsBarTarget.style.display = "flex";
  }

  close() {
    this.adminToolsBarTarget.parentNode.removeChild(this.adminToolsBarTarget);
    localStorage.setItem("hideAdminTools", "true");
  }
}
