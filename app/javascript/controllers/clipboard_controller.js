import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "message", "guidance", "button"];
  static values = { usageUrl: String };

  async copy() {
    if (this.copying) return;

    this.copying = true;
    this.buttonTarget.disabled = true;
    this.buttonTarget.textContent = "コピー中...";
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim());

      this.messageTarget.textContent = "コピーしました。外部AIへ貼り付けてください。";
      this.messageTarget.classList.remove("text-danger", "text-warning");
      this.messageTarget.classList.add("text-success");
      this.buttonTarget.textContent = "もう一度コピー";

      this.showGuidance();
      await this.recordUsage();
    } catch {
      this.messageTarget.textContent =
        "自動コピーできませんでした。プロンプト本文を選択して手動でコピーしてください。";
      this.messageTarget.classList.remove("text-success", "text-warning");
      this.messageTarget.classList.add("text-danger");
      this.buttonTarget.textContent = "コピーを再試行";

      this.showGuidance();
    } finally {
      this.copying = false;
      this.buttonTarget.disabled = false;
    }
  }

  showGuidance() {
    this.guidanceTarget.classList.remove("d-none");
  }

  async recordUsage() {
    if (!this.hasUsageUrlValue) return;

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
      const response = await fetch(this.usageUrlValue, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": csrfToken,
        },
        credentials: "same-origin",
      });

      if (!response.ok) throw new Error("Failed to record template usage");
    } catch {
      this.messageTarget.textContent =
        "コピーしましたが、最近使った履歴を更新できませんでした。";
      this.messageTarget.classList.remove("text-success", "text-danger");
      this.messageTarget.classList.add("text-warning");
    }
  }
}
