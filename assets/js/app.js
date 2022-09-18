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
    localStream = stream
    document.getElementById("local-video").srcObject = stream
  } catch (e) {
    console.log(e)
  }
}

let Hooks = {}

Hooks.TakePicture = {
  mounted() {
    initStream()

    this.el.addEventListener("click", event => {
      var canvas = document.getElementById("canvas");
      var video = document.getElementById("local-video");
      canvas.width = 400;
      canvas.height = 300;
      canvas.getContext('2d').drawImage(video, 0, 0, 400, 300);
      const picture = canvas.toDataURL("image/jpeg", 1.0)
      this.pushEvent("take", {"image": picture})
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
