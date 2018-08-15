//
//  OSLogSDLLogging.swift
//  SwiftTest GameController
//
//  Created by C.W. Betts on 8/14/18.
//

import Foundation
import SDL2.SDL_log
import os.log

private final class SDLLogging {
	private var logs: [Int32: OSLog]
	static private let logMapping: [Int32: String] = [SDL_LOG_CATEGORY_ERROR: "Error",
													  SDL_LOG_CATEGORY_ASSERT: "Assert",
													  SDL_LOG_CATEGORY_SYSTEM: "System",
													  SDL_LOG_CATEGORY_AUDIO: "Audio",
													  SDL_LOG_CATEGORY_VIDEO: "Video",
													  SDL_LOG_CATEGORY_RENDER: "Rendering",
													  SDL_LOG_CATEGORY_INPUT: "Input",
													  SDL_LOG_CATEGORY_TEST: "Test"]

	init() {
		logs = [SDL_LOG_CATEGORY_APPLICATION: OSLog(subsystem: "com.github.MaddTheSane.SwiftTest-GameController", category: "SwiftTest GameController")]
		logs.reserveCapacity(9)
	}
	
	func logForCategory(_ cat: Int32) -> OSLog? {
		if let log = logs[cat] {
			return log
		}
		if let logName = SDLLogging.logMapping[cat] {
			let newLog = OSLog(subsystem: "org.libsdl.SDL2", category: logName)
			logs[cat] = newLog
			return newLog
		}
		
		return nil
	}
}

private let ourLog = SDLLogging()


func osLogOutput(userData: UnsafeMutableRawPointer?, category: Int32, priority: SDL_LogPriority, message: UnsafePointer<CChar>?) {
	guard let logger = ourLog.logForCategory(category),
		let message = message,
		let swiftMessage = String(cString: message, encoding: .utf8) else {
		return
	}
	
	let logType: OSLogType
	let priorityName: String
	switch priority {
	case .verbose:
		logType = .info
		priorityName = "Verbose"
		
	case .debug:
		logType = .debug
		priorityName = "Debug"
		
	case .info:
		logType = .default
		priorityName = "Info"
		
	case .warn:
		logType = .error
		priorityName = "Warn"
		
	case .error:
		logType = .error
		priorityName = "Error"

	case .critical:
		logType = .fault
		priorityName = "Critical"

	default:
		logType = .default
		priorityName = "Unknown"
	}
	
	os_log("[%@] %@", log: logger, type: logType, priorityName, swiftMessage)
}
