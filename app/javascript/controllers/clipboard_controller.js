import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "message", "guidance", "button"];

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim());

      this.messageTarget.textContent = "コピーしました。外部AIへ貼り付けてください。";
      this.messageTarget.classList.remove("text-danger");
      this.messageTarget.classList.add("text-success");
      this.buttonTarget.textContent = "もう一度コピー";
      this.buttonTarget.classList.remove("btn-primary");
      this.buttonTarget.classList.add("btn-outline-success");
      this.showGuidance();
    } catch {
      this.messageTarget.textContent =
        "自動コピーできませんでした。プロンプト本文を選択して手動でコピーしてください。";
      this.messageTarget.classList.remove("text-success");
      this.messageTarget.classList.add("text-danger");
      this.buttonTarget.textContent = "コピーを再試行";
      this.buttonTarget.classList.remove("btn-outline-success");
      this.buttonTarget.classList.add("btn-primary");
      this.showGuidance();
    }
  }

  showGuidance() {
    this.guidanceTarget.classList.remove("d-none");
  }
}
