import Sharing from './modules/sharing';
import SignatureCounter from './modules/signature-counter';

window.PETS = window.PETS || {};
window.PETS.Sharing = Sharing;
window.PETS.SignatureCounter = SignatureCounter;

window.addEventListener('DOMContentLoaded', (event) => {
  const shareButton = document.getElementById('shareButton');
  const copyLinkButton = document.getElementById('copyLinkButton');

  if (shareButton && copyLinkButton) {
    new PETS.Sharing(shareButton, copyLinkButton);
  }

  const counter = document.querySelector('[data-module=signature-counter]');

  if (counter) {
    new SignatureCounter(counter, 10000);
  }
});
