import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "password", "passwordConfirmation" ]

  validatePassword() {
    if(this.passwordTarget.value != this.passwordConfirmationTarget.value) {
      this.passwordTarget.setCustomValidity("Passwords don't match");
    } else {
      this.passwordTarget.setCustomValidity("");
    }
  }
}
