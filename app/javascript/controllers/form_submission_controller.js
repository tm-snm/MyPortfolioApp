import { Controller } from "@hotwired/stimulus";

// Turbo serializes the form before submit-start. Lock editing until the
// response arrives so it cannot overwrite changes made after serialization.
export default class extends Controller {
  static targets = ["networkError"];
  static values = { signInPath: String };

  start(event) {
    if (event.target !== this.element) return;

    this.networkErrorTarget.hidden = true;
    const submitter = event.detail.formSubmission.submitter;
    this.buttons = Array.from(
      this.element.querySelectorAll('input[type="submit"], button')
    ).filter((button) => button !== submitter && !button.disabled);
    this.buttons.forEach((button) => { button.disabled = true; });

    this.inputs = this.element.querySelectorAll('input[type="text"]:not([readonly]), textarea:not([readonly])');
    this.inputs.forEach((input) => { input.readOnly = true; });
  }

  end() {
    this.buttons?.forEach((button) => { button.disabled = false; });
    this.buttons = [];
    this.inputs?.forEach((input) => { input.readOnly = false; });
    this.inputs = [];
  }

  preserveOnServerError(event) {
    if (event.target !== this.element || !event.detail.fetchResponse.serverError) return;

    event.preventDefault();
    this.networkErrorTarget.hidden = false;
  }

  requestFailed(event) {
    if (event.target === this.element) this.networkErrorTarget.hidden = false;
  }

  handleMissingFrame(event) {
    if (event.target !== this.element.closest("turbo-frame")) return;

    const { response, visit } = event.detail;
    const url = new URL(response.url);
    const returnedToSignIn = response.redirected &&
      url.origin === window.location.origin &&
      url.pathname === this.signInPathValue;

    if (returnedToSignIn) {
      event.preventDefault();
      visit(response);
    } else if (!response.ok) {
      event.preventDefault();
      this.networkErrorTarget.hidden = false;
    }
  }

  disconnect() {
    this.end();
  }
}
