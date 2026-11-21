import { Controller } from "@hotwired/stimulus";

// Turbo serializes the form before submit-start. Lock editing until the
// response arrives so it cannot overwrite changes made after serialization.
export default class extends Controller {
  static targets = ["networkError", "cancelLink", "status"];
  static values = { signInPath: String, validationErrorId: String };

  start(event) {
    if (event.target !== this.element) return;

    this.submitting = true;
    this.clearPreviousValidation();
    this.networkErrorTarget.hidden = true;
    const submitter = event.detail.formSubmission.submitter;
    if (this.hasStatusTarget) this.statusTarget.textContent = submitter?.dataset.turboSubmitsWith ?? "";
    if (this.hasCancelLinkTarget) {
      this.cancelLinkTarget.setAttribute("aria-disabled", "true");
      this.cancelLinkTarget.classList.add("disabled");
    }

    this.buttons = Array.from(
      this.element.querySelectorAll('input[type="submit"], button')
    ).filter((button) => button !== submitter && !button.disabled);
    this.buttons.forEach((button) => { button.disabled = true; });

    this.inputs = this.element.querySelectorAll('input[type="text"]:not([readonly]), textarea:not([readonly])');
    this.inputs.forEach((input) => { input.readOnly = true; });
  }

  preventWhileSubmitting(event) {
    if (this.submitting) event.preventDefault();
  }

  end() {
    this.submitting = false;
    if (this.hasStatusTarget) this.statusTarget.textContent = "";
    if (this.hasCancelLinkTarget) {
      this.cancelLinkTarget.removeAttribute("aria-disabled");
      this.cancelLinkTarget.classList.remove("disabled");
    }
    this.buttons?.forEach((button) => { button.disabled = false; });
    this.buttons = [];
    this.inputs?.forEach((input) => { input.readOnly = false; });
    this.inputs = [];
  }

  clearPreviousValidation() {
    if (!this.hasValidationErrorIdValue) return;

    const errorId = this.validationErrorIdValue;
    const escapedId = CSS.escape(errorId);
    const summary = this.element.querySelector(`#${escapedId}`);
    if (!summary) return;

    this.element.querySelectorAll(`[aria-describedby~="${escapedId}"]`).forEach((field) => {
      const descriptions = field.getAttribute("aria-describedby").trim().split(/\s+/)
        .filter((description) => description !== errorId);

      field.removeAttribute("aria-invalid");
      if (descriptions.length) {
        field.setAttribute("aria-describedby", descriptions.join(" "));
      } else {
        field.removeAttribute("aria-describedby");
      }
    });
    summary.remove();
  }

  preserveOnServerError(event) {
    if (event.target !== this.element || !event.detail.fetchResponse.serverError) return;

    event.preventDefault();
    this.showNetworkError();
  }

  requestFailed(event) {
    if (event.target === this.element) this.showNetworkError();
  }

  showNetworkError() {
    this.networkErrorTarget.hidden = false;
    this.networkErrorTarget.focus();
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
      this.showNetworkError();
    }
  }

  disconnect() {
    this.end();
  }
}
