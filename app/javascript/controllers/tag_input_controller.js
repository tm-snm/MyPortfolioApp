import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "selectedList", "emptyState", "candidate"];

  connect() {
    this.selectedNames = this.parseNames(this.inputTarget.value);
    this.inputTarget.value = "";
    this.render();
  }

  handleKeydown(event) {
    if (event.isComposing) return;
    if (!["Enter", ","].includes(event.key)) return;

    event.preventDefault();
    this.addFromInput();
  }

  add(event) {
    event.preventDefault();
    this.addFromInput();
  }

  selectCandidate(event) {
    this.addNames([event.currentTarget.dataset.tagName]);
    this.inputTarget.focus();
  }

  remove(event) {
    const tagName = event.currentTarget.dataset.tagName;

    this.selectedNames = this.selectedNames.filter((name) => name !== tagName);
    this.render();
    this.inputTarget.focus();
  }

  prepareSubmit(event) {
    if (event.target !== this.element.closest("form")) return;

    this.addFromInput();
    this.inputTarget.value = this.selectedNames.join(", ");
  }

  addFromInput() {
    this.addNames(this.parseNames(this.inputTarget.value));
    this.inputTarget.value = "";
  }

  addNames(names) {
    names.forEach((name) => {
      if (!this.selectedNames.includes(name)) {
        this.selectedNames.push(name);
      }
    });

    this.render();
  }

  parseNames(value) {
    return value
      .toString()
      .split(",")
      .map((name) => name.trim())
      .filter((name, index, names) => name && names.indexOf(name) === index);
  }

  render() {
    this.selectedListTarget.replaceChildren(
      ...this.selectedNames.map((name) => this.buildSelectedTag(name))
    );
    this.emptyStateTarget.classList.toggle(
      "d-none",
      this.selectedNames.length > 0
    );

    this.candidateTargets.forEach((candidate) => {
      const selected = this.selectedNames.includes(candidate.dataset.tagName);

      candidate.disabled = selected;
      candidate.setAttribute("aria-pressed", selected.toString());
    });
  }

  buildSelectedTag(name) {
    const badge = document.createElement("span");
    badge.className =
      "badge rounded-pill text-bg-secondary tag-badge d-inline-flex align-items-center gap-2";

    const label = document.createElement("span");
    label.textContent = name;

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.className = "btn-close btn-close-white";
    removeButton.setAttribute("aria-label", name + "を選択から外す");
    removeButton.dataset.tagName = name;
    removeButton.dataset.action = "tag-input#remove";

    badge.append(label, removeButton);

    return badge;
  }
}
