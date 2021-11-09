import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  close(event) {
    const flash = event.target.parentNode;
    flash.parentNode.removeChild(flash);
  }
}
