os       = require("os")
app      = require("electron").app
Position = require("electron-positioner")
errors   = require("../errors")
Updater  = require("../updater")
logs     = require("../electron/handlers/logs")
Tray     = require("../electron/handlers/tray")
Events   = require("../electron/handlers/events")
Renderer = require("../electron/handlers/renderer")

module.exports = {
  onDrop: ->

  onClick: (bounds, win) ->
    positioner = new Position(win)

    coords = positioner.calculate("trayCenter", bounds)

    ## store the coords on updater
    Updater.setCoords(coords)

    win.setPosition(coords.x, coords.y)

    if win.isVisible()
      win.hide()
    else
      win.show()

  onRightClick: ->

  onWindowAllClosed: (app) ->
    ## stop all the events
    Events.stop()

    ## exit when all windows are closed
    app.exit(0)

  getInitialShow: ->
    ## on linux initially show the window
    ## since it is not a tray application
    if os.platform() is "linux"
      true
    else
      ## for everything else do not show

      ## TODO: add a check here to see if
      ## the user is logged in. if they are
      ## not then immediately display the
      ## login window in the center!
      false

  ready: (options = {}) ->
    options.app = app

    ## handle right click to show context menu!
    ## handle drop events for automatically adding projects!
    ## use the same icon as the cloud app
    Renderer.create({
      width: 300
      height: 400
      resizable: false
      frame: false
      show: @getInitialShow()
      # devTools: true
      transparent: true
      # backgroundColor: "#FFFFFFFF"
      type: "INDEX"
      onBlur: ->
        return if @webContents.isDevToolsOpened()

        Renderer.hideAllUnlessAnotherWindowIsFocused()
      onFocus: ->
        Renderer.showAll()
    })
    .then (win) =>
      Events.start(options)

      Tray.display({
        onDrop: ->

        onClick: (e, bounds) =>
          @onClick(bounds, win)

        onRightClick: ->
    })

  run: (options) ->
    new Promise (resolve, reject) =>
      ## prevent chromium from throttling
      app.commandLine.appendSwitch("disable-renderer-backgrounding")

      app.on "window-all-closed", =>
        @onWindowAllClosed(app)

      app.on "ready", =>
        resolve @ready(options)
}