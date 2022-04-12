import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  initialize() {
    this.keysPressed = {};
    document.onkeydown = this.execute.bind(this);
    document.onkeyup = this.reset.bind(this);
  }

  reset() {
    this.keysPressed = {};
  }

  execute(e) {
    // short, manual de-bounce for keyboard shortcuts
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this._parseKeyboardShortcuts(e);
    }, 100);
  }

  _parseKeyboardShortcuts(e) {
    switch (e.key) {
      case "Alt":
        this.keysPressed["option"] = true;
        break;
      case "Meta":
        this.keysPressed["command"] = true;
        break;
      default:
        if (!e.key) {
          return;
        }
        this.keysPressed[e.key.toLowerCase()] = true;
    }

    if (this.keysPressed["escape"]) {
      const flashCloseButtons = document.querySelectorAll("#flashes .flash .close-flash-button");
      if (flashCloseButtons.length > 0) {
        return flashCloseButtons.forEach(button => { button.click(); });
      }

      const newWordBackButton = document.querySelector(".words-list-page #new-word-form .back-button");
      if (newWordBackButton) {
        return newWordBackButton.click();
      }

      const editWordBackButton = document.querySelector(".words-list-page .words-list-container .word-form .back-button");
      if (editWordBackButton) {
        return editWordBackButton.click();
      }

      // escape will "unfocus" a currently focused input or textarea field
      const focusedInputFields = document.querySelectorAll("input:focus,textarea:focus");
      if (focusedInputFields.length > 0) {
        return focusedInputFields.forEach(field => { field.blur(); });
      }

      // escape will go back one page from the search page
      if (window.location.pathname.match(/\/words\/search/g)) {
        return history.back();
      }
    }

    const focusedInputFieldsArePresent = document.querySelectorAll("input:focus,textarea:focus").length > 0;
    if (focusedInputFieldsArePresent) {
      // If we've got a form up with a field in focus, don't execute any more shortcuts
      return;
    }

    if (this.keysPressed["enter"]) {
      // Flash close buttons for flashes that are not already automatically collapsing
      const flashCloseButtons = document.querySelectorAll("#flashes .flash:not([data-flash-hide-in-ms-value]) .close-flash-button");
      if (flashCloseButtons.length > 0) {
        return flashCloseButtons.forEach(button => { button.click(); });
      }
    }

    if (this.keysPressed["command"] || this.keysPressed["option"] || this.keysPressed["shift"]) {
      // None of our remaining shortcuts use combo keys so bail here
      return;
    }

    if (this.keysPressed["w"]) {
      return document.getElementById("words-link").click();
    }
    if (this.keysPressed["c"]) {
      document.getElementById("words-link").click();
      return Turbo.visit(`${window.location}?filter=cards_not_created&order=oldest_first`);
    }
    if (this.keysPressed["n"]) {
      const newWordBtton = document.querySelector("#new-word-form .new-word");
      if (newWordBtton) {
        return newWordBtton.click();
      }
    }
    if (this.keysPressed["f"]) {
      return document.getElementById("word-search-link").click();
    }
    if (this.keysPressed["i"] || this.keysPressed["e"]) {
      return document.querySelector(".in-out-link").click();
    }
    if (this.keysPressed["s"]) {
      return document.getElementById("user-stats-link").click();
    }
    if (this.keysPressed["k"]) {
      return document.getElementById("kanji-link").click();
    }
    if (this.keysPressed["h"]) {
      return Turbo.visit("/keyboard_shortcuts");
    }
    if (this.keysPressed["a"]) {
      return Turbo.visit("/media_tools/audio?show_latest_conversion=true");
    }
  }
}
