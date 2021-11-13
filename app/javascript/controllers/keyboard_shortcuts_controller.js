import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    let keysPressed = {}
    document.onkeydown = function(e) {
      if (window.disableJpstudyKeyboardShorcuts) {
        return;
      }
      switch (e.key) {
        // letters reflect variant printed with `shift + option + key`
        case "Shift":
          keysPressed["shift"] = true;
          break;
        case "Alt":
          keysPressed["option"] = true;
          break;
        case "Escape":
          keysPressed["escape"] = true;
          break;
        case "Enter":
          keysPressed["enter"] = true;
          break;
        case "Í":
          keysPressed["s"] = true;
          break;
        case "„":
          keysPressed["w"] = true;
          break;
        case "˜":
          keysPressed["n"] = true;
          break;
        case "Å":
          keysPressed["a"] = true;
          break;
        case "Ç":
          keysPressed["c"] = true;
          break;
        case "´":
          keysPressed["e"] = true;
          break;
        case "ˆ":
          keysPressed["i"] = true;
          break;
        case "ˇ":
          keysPressed["t"] = true;
          break;
      }

      if (keysPressed["shift"] && keysPressed["option"] && keysPressed["w"]) {
        e.preventDefault(); // stops key value from being entered into an input field
        return window.location = "/words";
      }
      if (keysPressed["shift"] && keysPressed["option"] && keysPressed["s"]) {
        e.preventDefault();
        return window.location = "/words/search";
      }
      if (
        (keysPressed["shift"] && keysPressed["option"] && keysPressed["n"]) ||
        (keysPressed["shift"] && keysPressed["option"] && keysPressed["a"])
      ) {
        e.preventDefault();
        const newWordBtton = document.querySelector("#new-word-form .new-word");
        if (newWordBtton) {
          return newWordBtton.click();
        }
        return window.location = "/words/new";
      }
      if (keysPressed["shift"] && keysPressed["option"] && keysPressed["c"]) {
        e.preventDefault();
        return window.location = "/words?filter=cards_not_created";
      }
      if (keysPressed["shift"] && keysPressed["option"] && keysPressed["e"]) {
        e.preventDefault();
        return window.location = "/words/export";
      }
      if (keysPressed["shift"] && keysPressed["option"] && keysPressed["i"]) {
        e.preventDefault();
        return window.location = "/words/import";
      }
      if (keysPressed["escape"]) {
        const flashCloseButtons = document.querySelectorAll("#flashes .flash .close-flash-button");
        if (flashCloseButtons.length > 0) {
          return flashCloseButtons.forEach(button => { button.click(); });
        }

        const newWordBackButton = document.querySelector(".words-list-page #new-word-form .back-button");
        if (newWordBackButton) {
          return newWordBackButton.click();
        }
      }
      if (keysPressed["enter"]) {
        const flashCloseButtons = document.querySelectorAll("#flashes .flash .close-flash-button");
        if (flashCloseButtons.length > 0) {
          return flashCloseButtons.forEach(button => { button.click(); });
        }
      }
    };

    document.onkeyup = function() {
      // reset on key up
      keysPressed = {}
    }
  }
}
