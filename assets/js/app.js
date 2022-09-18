// esbuild automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "config.exs".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

async function initStream() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({audio: true, video: true, width: "1280"})
    document.getElementById("local-video").srcObject = stream
  } catch (e) {
    console.log(e)
  }
}

let Hooks = {}

Hooks.TakePicture = {
  mounted() {
    initStream()

    const video = document.getElementById("local-video");

    const canvas = document.getElementById("canvas");
    canvas.width = 400;
    const context = canvas.getContext("2d");
    const canvasGray = document.getElementById("canvas-gray");
    canvasGray.width = 400;
    const contextGray = canvasGray.getContext("2d");

    this.el.addEventListener("click", event => {
      const height = parseInt(400 * video.videoHeight / video.videoWidth);
      canvas.height = height;
      canvasGray.height = height;
      canvas.getContext('2d').drawImage(video, 0, 0, 400, height);
      const pixel = context.getImageData(0, 0, 400, height)
      this.pushEvent("take", pixel, (payload) => {
        let imageData = new ImageData(
          new Uint8ClampedArray(payload.image),
          400,
          height
        );
        contextGray.putImageData(imageData, 0, 0);
      })
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
