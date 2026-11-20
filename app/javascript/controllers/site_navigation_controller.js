import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "toggle"];

  close(event) {
    if (!this.isMobileMenuOpen) return;

    event.preventDefault();
    this.toggleTarget.focus();
    window.bootstrap.Collapse.getOrCreateInstance(this.menuTarget, { toggle: false }).hide();
  }

  focusDestination(event) {
    if (!this.isMobileMenuOpen) return;

    const destination = event.detail.url;
    document.addEventListener("turbo:load", ({ detail }) => {
      if (detail.url === destination && document.activeElement === document.body) {
        document.getElementById("main-content")?.focus({ preventScroll: true });
      }
    }, { once: true });
  }

  get isMobileMenuOpen() {
    return this.toggleTarget.getClientRects().length > 0 &&
      this.toggleTarget.getAttribute("aria-expanded") === "true";
  }
}
