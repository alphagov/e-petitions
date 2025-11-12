import Sharing from './modules/sharing'

window.PETS = window.PETS || {};
window.PETS.Sharing = Sharing;

window.addEventListener('DOMContentLoaded', (event) => {
  const shareButton = document.getElementById('shareButton');
  const copyLinkButton = document.getElementById('copyLinkButton');

  if (shareButton && copyLinkButton) {
    new PETS.Sharing(shareButton, copyLinkButton);
  }
});
