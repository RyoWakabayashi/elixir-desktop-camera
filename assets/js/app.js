// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// video にカメラ映像を流す
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

// 写真撮影用フック
Hooks.TakePicture = {
  mounted() {
    initStream()

    const width = 400;
    const video = document.getElementById("local-video");
    const canvas = document.getElementById("canvas");
    const canvasGray = document.getElementById("canvas-gray");

    canvas.width = width;
    canvasGray.width = width;

    const context = canvas.getContext("2d");
    const contextGray = canvasGray.getContext("2d");

    // button クリック時
    this.el.addEventListener("click", event => {
      // canvas にカメラ映像を貼り付け
      const height = parseInt(width * video.videoHeight / video.videoWidth);
      canvas.height = height;
      canvasGray.height = height;
      canvas.getContext('2d').drawImage(video, 0, 0, width, height);

      // ピクセルデータを取得
      const pixel = context.getImageData(0, 0, width, height)["data"].toString()

      // ピクセルデータをElixirに送信
      this.pushEvent("take", {pixel}, (payload) => {
        let imageData = new ImageData(
          new Uint8ClampedArray(payload.image),
          width,
          height
        );
        // ピクセルデータを canvas に貼り付け
        contextGray.putImageData(imageData, 0, 0);
      })
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

