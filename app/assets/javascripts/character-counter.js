import CharacterCounter from './modules/character-counter';

window.PETS = window.PETS || {};
window.PETS.CharacterCounter = CharacterCounter;

window.addEventListener('DOMContentLoaded', (event) => {
  const textareas = document.querySelectorAll('textarea[data-max-length]');

  for (const textarea of textareas) {
    new CharacterCounter(textarea);
  }
});
