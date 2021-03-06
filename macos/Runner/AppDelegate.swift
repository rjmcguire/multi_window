import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate, FlutterPlugin {
    var _controllers: [(String, FlutterViewController, NSWindow)] = []
    var controllers: [(String, FlutterViewController, NSWindow)] {
        get {
            let appDelegate = NSApp.delegate as! AppDelegate
            return appDelegate._controllers
        }
        set {
            let appDelegate = NSApp.delegate as! AppDelegate
            appDelegate._controllers = newValue
        }
    }


    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        createNewWindow(key: "base", x: 300, y: 300, width: 1280, height: 720)
    }

    func createNewWindow(key: String, x: Double? = nil, y: Double? = nil, width: Int? = nil, height: Int? = nil) {
        let flutterController = FlutterViewController.init()
        let window = NSWindow()
        window.styleMask = NSWindow.StyleMask(rawValue: 0xf)
        window.backingType = .buffered
        window.contentViewController = flutterController
        if let screen = window.screen {
            let screenRect = screen.visibleFrame
            let newWidth = width ?? Int(screenRect.maxX / 2)
            let newHeight = height ?? Int(screenRect.maxY / 2)
            var newOriginX: CGFloat = (screenRect.maxX / 2) - CGFloat(Double(newWidth) / 2)
            var newOriginY: CGFloat = (screenRect.maxY / 2) - CGFloat(Double(newHeight) / 2)
            if (x != nil) { newOriginX = CGFloat(x!) }
            if (y != nil) { newOriginY = CGFloat(y!) }
            window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
            window.setContentSize(NSSize(width: newWidth, height: newHeight))
        }
        RegisterGeneratedPlugins(registry: flutterController)
        controllers.append((key, flutterController, window))
        AppDelegate.register(with: flutterController.registrar(forPlugin: "AppDelegate"))
        let windowController = NSWindowController()
        windowController.contentViewController = window.contentViewController
        windowController.shouldCascadeWindows = true
        windowController.window = window
        windowController.showWindow(self)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channelName = "window_controller"
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
        let instance = AppDelegate()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createWindow":
            let args = call.arguments as? [String: Any]
            let width: Int? = args?["width"] as? Int
            let height: Int? = args?["height"] as? Int
            let x: Double? = args?["x"] as? Double
            let y: Double? = args?["y"] as? Double
            let key: String = args?["key"] as! String
            createNewWindow(
                key: key,
                x: x,
                y: y,
                width: width,
                height: height
            )
            result(true)
            break
        case "closeWindow":
            let args = call.arguments as? [String: Any]
            let key: String! = args?["key"] as? String
            result(closeWindow(_key: key))
            break
        case "windowCount":
            result(controllers.count)
            break
        case "keyIndex":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let index = controllers.firstIndex(where: { (key, cont, win) -> Bool in
                if (key == _key) {
                    return true
                }
                return false
            })
            result(index ?? 0)
            break
        case "getWindowStats":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let index = controllers.firstIndex(where: { (key, cont, win) -> Bool in
                if (key == _key) {
                    return true
                }
                return false
            })
            let controller = controllers[index!]
            let screen = controller.2.frame
            let origin = screen.origin
            let size = screen.size
            var _args: [String: Any?] = [:]
            _args["offsetX"] = Double(origin.x)
            _args["offsetY"] = Double(origin.y)
            _args["width"] = Double(size.width)
            _args["height"] = Double(size.height)
            result(_args)
        case "moveWindow":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let x: Double = args?["x"] as! Double
            let y: Double = args?["y"] as! Double
            let index = controllers.firstIndex(where: { (key, cont, win) -> Bool in
                if (key == _key) {
                    return true
                }
                return false
            })
            let controller = controllers[index!]
            let screen = controller.2
            screen.setFrameOrigin(NSPoint(x: x, y: y))
            result(true)
        case "resizeWindow":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let width: Double = args?["width"] as! Double
            let height: Double = args?["height"] as! Double
            let index = controllers.firstIndex(where: { (key, cont, win) -> Bool in
                if (key == _key) {
                    return true
                }
                return false
            })
            let controller = controllers[index!]
            let screen = controller.2
            screen.setContentSize(NSSize(width: width, height: height))
            result(true)
        case "lastWindowKey":
            let controller = controllers.last
            let _instanceKey = controller?.0;
            result(_instanceKey)
        default:
            result(FlutterMethodNotImplemented)
        }
    }


    func closeWindow(_key: String) -> Bool {
        do {
            let index = controllers.firstIndex(where: { (key, cont, win) -> Bool in
                if (key == _key) {
                    return true
                }
                return false
            })
            let controller = controllers[index ?? 0]
            controller.1.viewWillDisappear()
            controller.2.close()
            controller.1.viewDidDisappear()
            controllers.remove(at: index ?? 0)
             return true
        } catch {
             return false
        }
    }
}
