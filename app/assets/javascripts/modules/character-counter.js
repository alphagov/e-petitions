export default class CharacterCounter {
  constructor(textarea) {
    this.textarea = textarea;
    this.counter = textarea.parentNode.querySelector('.character-count');
    this.maxLength = parseInt(textarea.dataset.maxLength);

    const ariaId = `char-count-${textarea.id}`;

    this.counter.setAttribute('id', ariaId);
    this.counter.setAttribute('aria-atomic', 'true');
    this.counter.setAttribute('role', 'status');

    this.textarea.setAttribute('aria-controls', ariaId);

    textarea.addEventListener('change', () => {
      this.updateCount();
    });

    textarea.addEventListener('keyup', () => {
      this.updateCount();
    });

    textarea.addEventListener('paste', () => {
      this.updateCount();
    });

    window.addEventListener('pageshow', () => {
      this.updateCount();
    });

    this.updateCount();
  }

  updateCount() {
    const contents = this.textarea.value;
    const characters = contents.length;
    const remaining = this.maxLength - characters;

    this.counter.classList.toggle('too-many-characters', remaining < 0);
    this.textarea.classList.toggle('form-control--error', remaining < 0);

    this.statusMessage(remaining);
  }

  statusMessage(remaining) {
    const characters = Math.abs(remaining) == 1 ? 'character' : 'characters';
    const status = remaining < 0 ? 'too many' : 'remaining';

    this.counter.textContent = `You have ${Math.abs(remaining)} ${characters} ${status}`;
  }
}
