//
//  System.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import JavaScriptCore

// Protocol must be declared with `@objc`
@objc protocol System_JSExports: JSExport {
    var width: Float { get }
    var height: Float { get }
    
    static func setTimeout(_ callback : JSValue,_ ms : Double) -> String
    static func clearTimeout(_ identifier: String)
    static func setInterval(_ callback : JSValue,_ ms : Double) -> String

    static func log(_ string: String)

    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

var timers = [String: Timer]()

class System            : NSObject, System_JSExports
{
    var width           : Float = 0
    var height          : Float = 0

    ///
    override init()
    {
        super.init()
    }

    class func log(_ string: String) {
        print(string)
    }
    
    static func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)

        timer?.invalidate()
    }

    class func setInterval(_ callback: JSValue,_ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms, repeats: true)
    }

    class func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms , repeats: false)
    }

    class func createTimer(callback: JSValue, ms: Double, repeats : Bool) -> String {
        let timeInterval  = ms/1000.0

        let uuid = NSUUID().uuidString

        // make sure that we are queueing it all in the same executable queue...
        // JS calls are getting lost if the queue is not specified... that's what we believe... ;)
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: callback,
                                             repeats: repeats)
            timers[uuid] = timer
        })


        return uuid
    }
    
    @objc static func callJsCallback(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)

        callback.call(withArguments: nil)
    }
}
