export default class Sharing {
  constructor(shareButton, copyLinkButton) {
    if (navigator.share) {
      shareButton.hidden = false;

      shareButton.addEventListener('click', async () => {
        await this.sharePetition();
      });
    } else if (navigator.clipboard) {
      copyLinkButton.hidden = false;

      copyLinkButton.addEventListener('click', async () => {
        await this.copyUrlToClipboard();
      });
    }
  }

  async sharePetition(event) {
    try {
      await navigator.share(this.shareData);
    } catch (error) {
      console.error(error.message);
    }
  }

  async copyUrlToClipboard() {
    try {
      await navigator.clipboard.writeText(this.url);
    } catch (error) {
      console.error(error.message);
    }
  }

  getMetaContent(property) {
    const meta = document.querySelector(`meta[property='og:${property}']`);
    return meta ? meta.content : null;
  }

  get title() {
    return this.getMetaContent('title');
  }

  get description() {
    return this.getMetaContent('description');
  }

  get url() {
    return this.getMetaContent('url');
  }

  get shareData() {
    return { title: this.title, text: this.description, url: this.url }
  }
}
