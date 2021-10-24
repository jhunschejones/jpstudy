import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String };

  confirm(event) {
    console.log(this.messageValue);
    if (!(window.confirm(this.messageValue))) {
      event.preventDefault();
      event.stopImmediatePropagation();
    };
  }
}
