import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "message"];

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim());

      this.messageTarget.textContent = "コピーしました";
    } catch (error) {
      this.messageTarget.textContent = "コピーに失敗しました";
      console.error(error);
    }
  }
}
