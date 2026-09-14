import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "list", "status"];
  static values = {
    url: String,
    delay: { type: Number, default: 250 },
  };

  connect() {
    this.titles = [];
    this.activeIndex = -1;
  }

  disconnect() {
    this.cancelScheduledSearch();
    this.cancelRequest();
    clearTimeout(this.blurTimeout);
  }

  search(event) {
    if (event.isComposing) return;

    this.cancelScheduledSearch();
    this.cancelRequest();

    const query = this.inputTarget.value.trim();

    if (query.length < 2) {
      this.clearResults();
      return;
    }

    this.searchTimeout = setTimeout(() => {
      this.fetchTitles(query);
    }, this.delayValue);
  }

  async fetchTitles(query) {
    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("q", query);
    const abortController = new AbortController();
    this.abortController = abortController;

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
        signal: abortController.signal,
      });

      if (!response.ok) throw new Error("Autocomplete request failed");

      const data = await response.json();

      if (this.inputTarget.value.trim() !== query) return;

      const titles = Array.isArray(data.titles)
        ? data.titles.filter((title) => typeof title === "string")
        : [];

      this.renderTitles(titles);
    } catch (error) {
      if (error.name === "AbortError") return;

      this.renderMessage(
        "候補を取得できませんでした。そのまま検索できます。",
        "text-danger"
      );
    } finally {
      if (this.abortController === abortController) {
        this.abortController = null;
      }
    }
  }

  handleKeydown(event) {
    if (event.isComposing) return;

    switch (event.key) {
      case "ArrowDown":
        this.moveSelection(event, 1);
        break;
      case "ArrowUp":
        this.moveSelection(event, -1);
        break;
      case "Enter":
        this.selectActiveTitle(event);
        break;
      case "Escape":
        event.preventDefault();
        this.closeList();
        break;
    }
  }

  handleBlur() {
    this.blurTimeout = setTimeout(() => this.closeList(), 100);
  }

  preventBlur(event) {
    event.preventDefault();
  }

  select(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.applyTitle(this.titles[index]);
  }

  moveSelection(event, offset) {
    if (this.titles.length === 0) return;

    event.preventDefault();

    if (this.activeIndex < 0) {
      this.activeIndex = offset > 0 ? 0 : this.titles.length - 1;
    } else {
      this.activeIndex =
        (this.activeIndex + offset + this.titles.length) % this.titles.length;
    }

    this.updateSelection();
  }

  selectActiveTitle(event) {
    if (this.activeIndex < 0) return;

    event.preventDefault();
    this.applyTitle(this.titles[this.activeIndex]);
  }

  applyTitle(title) {
    if (!title) return;

    this.inputTarget.value = title;
    this.closeList();
    this.statusTarget.textContent =
      "「" + title + "」を検索欄へ入力しました。";
    this.inputTarget.focus();
  }

  renderTitles(titles) {
    this.titles = titles;
    this.activeIndex = -1;

    if (titles.length === 0) {
      this.renderMessage("一致するタイトル候補はありません。", "text-muted");
      return;
    }

    const options = titles.map((title, index) =>
      this.buildOption(title, index)
    );

    this.listTarget.replaceChildren(...options);
    this.openList();
    this.statusTarget.textContent =
      titles.length + "件のタイトル候補があります。";
  }

  renderMessage(message, className) {
    this.titles = [];
    this.activeIndex = -1;

    const item = document.createElement("div");
    item.className = "list-group-item " + className;
    item.textContent = message;
    item.setAttribute("role", "presentation");

    this.listTarget.replaceChildren(item);
    this.openList();
    this.statusTarget.textContent = message;
  }

  buildOption(title, index) {
    const option = document.createElement("button");
    option.type = "button";
    option.id = "card-title-autocomplete-option-" + index;
    option.className =
      "autocomplete-option list-group-item list-group-item-action";
    option.textContent = title;
    option.setAttribute("role", "option");
    option.setAttribute("aria-selected", "false");
    option.dataset.index = index;
    option.dataset.action =
      "mousedown->card-title-autocomplete#preventBlur click->card-title-autocomplete#select";

    return option;
  }

  updateSelection() {
    const options = this.listTarget.querySelectorAll('[role="option"]');

    options.forEach((option, index) => {
      const selected = index === this.activeIndex;
      option.classList.toggle("active", selected);
      option.setAttribute("aria-selected", selected.toString());
    });

    const activeOption = options[this.activeIndex];
    this.inputTarget.setAttribute("aria-activedescendant", activeOption.id);
    activeOption.scrollIntoView({ block: "nearest" });
  }

  openList() {
    this.listTarget.classList.remove("d-none");
    this.inputTarget.setAttribute("aria-expanded", "true");
  }

  closeList() {
    this.listTarget.classList.add("d-none");
    this.inputTarget.setAttribute("aria-expanded", "false");
    this.inputTarget.removeAttribute("aria-activedescendant");
    this.activeIndex = -1;
  }

  clearResults() {
    this.titles = [];
    this.listTarget.replaceChildren();
    this.statusTarget.textContent = "";
    this.closeList();
  }

  cancelScheduledSearch() {
    clearTimeout(this.searchTimeout);
  }

  cancelRequest() {
    this.abortController?.abort();
    this.abortController = null;
  }
}
