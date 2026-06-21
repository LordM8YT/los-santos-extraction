function copyToClipboard(text) {
    const element = document.createElement("textarea");
    element.value = text;
    document.body.appendChild(element);
    element.select();
    document.execCommand("copy");
    document.body.removeChild(element);
}

window.addEventListener("message", (event) => {
    if (!event.data || event.data.action !== "copy" || typeof event.data.text !== "string") {
        return;
    }

    copyToClipboard(event.data.text);
});
