import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.frame = requestAnimationFrame(() => this.element.focus());
  }

  disconnect() {
    cancelAnimationFrame(this.frame);
  }
}
