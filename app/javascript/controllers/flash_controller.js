import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "flashContainer" ]

  static values = { hideInMs: String }

  initialize() {
    if (this.hasHideInMsValue) {
      const transitionTimeMs = 350; // needs to match transition time set in css
      setTimeout(() => {
        this.collapse(transitionTimeMs);
        setTimeout(() => {
          // remove the flash from the DOM after collapse animation has finished if it still exists
          if (this.flashContainerTarget.parentNode) {
            this.close();
          }
        }, transitionTimeMs);
      }, parseInt(this.hideInMsValue));
    }
  }

  close() {
    this.flashContainerTarget.parentNode.removeChild(this.flashContainerTarget);
  }

  collapse(transitionTimeMs = 350) {
    // get the height of the element's inner content, regardless of its actual size
    const sectionHeight = this.flashContainerTarget.scrollHeight;

    // explicitly set the element's height to its current pixel height, so we
    // aren't transitioning out of 'auto'
    this.flashContainerTarget.style.height = `${sectionHeight}px`;

    // on the next frame (as soon as the previous style change has taken effect),
    // set the collapse transition (also reqires `overflow: hidden;` on the element)
    requestAnimationFrame(() => {
      this.flashContainerTarget.style.transition = `height ${transitionTimeMs}ms ease-out`;

      // on the next frame (as soon as the previous style change has taken effect),
      // have the element transition to `height: 0px, margin-bottom: 0px;`
      requestAnimationFrame(() => {
        this.flashContainerTarget.style.height = "0px";
      });
    });
  }
}
