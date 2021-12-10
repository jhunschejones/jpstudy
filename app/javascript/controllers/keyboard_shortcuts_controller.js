import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    let keysPressed = {}
    document.onkeydown = function(e) {
      if (window.disableJpstudyKeyboardShorcuts) {
        return;
      }
      switch (e.key) {
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
        case "Meta":
          keysPressed["command"] = true;
          break;

        // === normal key variants
        case "a":
          keysPressed["a"] = true;
          break;
        case "c":
          keysPressed["c"] = true;
          break;
        case "d":
          keysPressed["d"] = true;
          break;
        case "e":
          keysPressed["e"] = true;
          break;
        case "f":
          keysPressed["f"] = true;
          break;
        case "i":
          keysPressed["i"] = true;
          break;
        case "n":
          keysPressed["n"] = true;
          break;
        case "s":
          keysPressed["s"] = true;
          break;
        case "t":
          keysPressed["t"] = true;
          break;
        case "u":
          keysPressed["u"] = true;
          break;
        case "w":
          keysPressed["w"] = true;
          break;

        // === `shift + option + key` variants
        // case "Å":
        //   keysPressed["a"] = true;
        //   break;
        // case "Ç":
        //   keysPressed["c"] = true;
        //   break;
        // case "Î":
        //   keysPressed["d"] = true;
        //   break;
        // case "´":
        //   keysPressed["e"] = true;
        //   break;
        // case "Ï":
        //   keysPressed["f"] = true;
        //   break;
        // case "ˆ":
        //   keysPressed["i"] = true;
        //   break;
        // case "˜":
        //   keysPressed["n"] = true;
        //   break;
        // case "Í":
        //   keysPressed["s"] = true;
        //   break;
        // case "ˇ":
        //   keysPressed["t"] = true;
        //   break;
        // case "¨":
        //   keysPressed["u"] = true;
        //   break;
        // case "„":
        //   keysPressed["w"] = true;
        //   break;
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
        if (window.location.pathname == "/words/search") {
          return history.back();
        }
      }
      if (keysPressed["enter"]) {
        const flashCloseButtons = document.querySelectorAll("#flashes .flash .close-flash-button");
        if (flashCloseButtons.length > 0) {
          return flashCloseButtons.forEach(button => { button.click(); });
        }
      }

      const focusedInputFieldsArePresent = document.querySelectorAll("input:focus,textarea:focus").length > 0;
      if (focusedInputFieldsArePresent) {
        // If we've got a form up with a field in focus, don't execute any more shortcuts
        return;
      }

      if (keysPressed["command"] || keysPressed["option"] || keysPressed["shift"]) {
        // None of our remaining shortcuts use combo keys
        return;
      }

      if (keysPressed["w"] || keysPressed["a"]) {
        e.preventDefault(); // stops key value from being entered into an input field
        return Turbo.visit("/words");
      }
      if (keysPressed["c"]) {
        e.preventDefault();
        return Turbo.visit("/words?filter=cards_not_created&order=oldest_first");
      }
      if (keysPressed["n"]) {
        e.preventDefault();
        const newWordBtton = document.querySelector("#new-word-form .new-word");
        if (newWordBtton) {
          return newWordBtton.click();
        }
        return Turbo.visit("/words/new");
      }
      if (keysPressed["f"]) {
        e.preventDefault();
        return Turbo.visit("/words/search");
      }
      if (keysPressed["e"]) {
        e.preventDefault();
        return Turbo.visit("/words/export");
      }
      if (keysPressed["i"]) {
        e.preventDefault();
        return Turbo.visit("/words/import");
      }
      if (keysPressed["s"]) {
        e.preventDefault();
        return document.querySelector("#stats-nav-link").click();
      }
    };

    document.onkeyup = function() {
      // reset on key up
      keysPressed = {}
    }
  }
}
