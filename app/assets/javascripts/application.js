import CharacterCounter from './modules/character-counter'
import SignatureCounter from './modules/signature-counter'

window.PETS = window.PETS || {};
window.PETS.CharacterCounter = CharacterCounter;
window.PETS.SignatureCounter = SignatureCounter;

window.addEventListener('DOMContentLoaded', (event) => {
  const counters = document.querySelectorAll('.signature-count');
  const textareas = document.querySelectorAll('textarea[data-max-length]');

  for (const counter of counters) {
    new SignatureCounter(counter, 10000);
  }

  for (const textarea of textareas) {
    new CharacterCounter(textarea);
  }
});
