import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "flashContainer" ]

  static values = { hideInSec: String }

  initialize() {
    if (this.hasHideInSecValue) {
      const waitMs = 1000;
      const animationMs = parseFloat(this.hideInSecValue) * 1000;

      setTimeout(() => {
        this.collapse();
        // remove the flash from the DOM after collapse animation has finished
        setTimeout(() => {
          if (this.flashContainerTarget.parentNode) {
            this.close();
          }
        }, animationMs);
      }, waitMs);
    }
  }

  close() {
    this.flashContainerTarget.parentNode.removeChild(this.flashContainerTarget);
  }

  // Borrowed from: https://css-tricks.com/using-css-transitions-auto-dimensions/
  collapse() {
    // get the height of the element's inner content, regardless of its actual size
    const sectionHeight = this.flashContainerTarget.scrollHeight;

    // set the collapse transition (also reqires `overflow: hidden;` on the element)
    // for this element we'll need to collapse the height and margin bottom
    const elementTransition = `height ${this.hideInSecValue}s ease-out, margin-bottom ${this.hideInSecValue}s ease-out`;

    // on the next frame (as soon as the previous style change has taken effect),
    // explicitly set the element's height to its current pixel height, so we
    // aren't transitioning out of 'auto'
    requestAnimationFrame(() => {
      this.flashContainerTarget.style.height = `${sectionHeight}px`;
      this.flashContainerTarget.style.transition = elementTransition;

      // on the next frame (as soon as the previous style change has taken effect),
      // have the element transition to `height: 0px, margin-bottom: 0px;`
      requestAnimationFrame(() => {
        this.flashContainerTarget.style.height = "0px";
        this.flashContainerTarget.style.marginBottom = "0px";
      });
    });
  }
}
