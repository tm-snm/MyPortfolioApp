import { Controller } from "@hotwired/stimulus";

// Turbo serializes the form before submit-start. Keep input values and
// formaction intact, and only lock additional submit buttons.
export default class extends Controller {
  start(event) {
    if (event.target !== this.element) return;

    const submitter = event.detail.formSubmission.submitter;
    this.buttons = Array.from(
      this.element.querySelectorAll('input[type="submit"], button[type="submit"]')
    ).filter((button) => button !== submitter && !button.disabled);
    this.buttons.forEach((button) => { button.disabled = true; });
  }

  end() {
    this.buttons?.forEach((button) => { button.disabled = false; });
    this.buttons = [];
  }

  disconnect() {
    this.end();
  }
}
