export default class ParliamentMenu {
  menuButton;
  menuIsOpen = true;

  constructor(container) {
    this.menuButton = container.querySelector('button');

    console.log(container);

    this.menuButton.addEventListener('click', () => {
      this.handleMenuButtonClick();
    });

    const currentItem = container.querySelector('li[aria-current=true]');

    if (!currentItem) {
      this.menuIsOpen = false;
      this.menuButton.setAttribute('aria-expanded', this.ariaExpanded);
    }
  }

  handleMenuButtonClick() {
    this.menuIsOpen = !this.menuIsOpen;
    this.menuButton.setAttribute('aria-expanded', this.ariaExpanded);
  }

  get ariaExpanded() {
    return this.menuIsOpen.toString();
  }
}
