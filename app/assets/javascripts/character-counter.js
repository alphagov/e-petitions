//= require modules/character-counter

window.addEventListener('DOMContentLoaded', (event) => {
  const textareas = document.querySelectorAll('textarea[data-max-length]');

  for (const textarea of textareas) {
    new PETS.CharacterCounter(textarea);
  }
});
