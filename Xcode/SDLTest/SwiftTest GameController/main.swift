//
//  AppDelegate.swift
//  SwiftTest GameController
//
//  Created by C.W. Betts on 8/14/18.
//

import Foundation
import SDL2
import SDL2.SDL_log
import SDL2.SDL_gamecontroller
import SDL2.SDL_surface

var SCREEN_WIDTH: Int32 { return 512 }
var SCREEN_HEIGHT: Int32 { return 320 }


private struct ButtonPosition {
  var x: Int32
  var y: Int32
}
/// This is indexed by `SDL_GameControllerButton`.
private let buttonPositions: [ButtonPosition] =
	[
		ButtonPosition(x: 387, y: 167), // A
		ButtonPosition(x: 431, y: 132), // B
		ButtonPosition(x: 342, y: 132), // X
		ButtonPosition(x: 389, y: 101), // Y
		ButtonPosition(x: 174, y: 132), // BACK
		ButtonPosition(x: 233, y: 132), // GUIDE
		ButtonPosition(x: 289, y: 132), // START
		ButtonPosition(x: 75, y: 154), // LEFTSTICK
		ButtonPosition(x: 305, y: 230), // RIGHTSTICK
		ButtonPosition(x: 77, y: 40), // LEFTSHOULDER
		ButtonPosition(x: 396, y: 36), // RIGHTSHOULDER
		ButtonPosition(x: 154, y: 188), // DPAD_UP
		ButtonPosition(x: 154, y: 249), // DPAD_DOWN
		ButtonPosition(x: 116, y: 217), // DPAD_LEFT
		ButtonPosition(x: 186, y: 217)  // DPAD_RIGHT
]

private struct AxisPosition {
	var x: Int32
	var y: Int32
	var angle: Double
}
/// This is indexed by `SDL_GameControllerAxis`.
private let AxisPositions: [AxisPosition] = [
	AxisPosition(x: 74, y: 153, angle: 270.0),	// LEFTX
	AxisPosition(x: 74, y: 153, angle: 0.0),	// LEFTY
	AxisPosition(x: 306, y: 231, angle: 270.0),	// RIGHTX
	AxisPosition(x: 306, y: 231, angle: 0.0),	// RIGHTY
	AxisPosition(x: 91, y: -20, angle: 0.0), 	// TRIGGERLEFT
	AxisPosition(x: 375, y: -20, angle: 0.0), 	// TRIGGERRIGHT
]

private var screen: SDL_RendererPtr? = nil
private var retval = SDL_bool.FALSE
private var done = false
private var background: SDL_TexturePtr? = nil
private var button: SDL_TexturePtr? = nil
private var axis: SDL_TexturePtr? = nil

private func loadTexture(_ renderer: SDL_RendererPtr, file: UnsafePointer<Int8>, transparent: Bool) -> SDL_TexturePtr? {
	/* Load the sprite image */
	guard let temp = SDL_LoadBMP(file) else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't load %s: %s", file, SDL_GetError());
		return nil;
	}
	defer {
		SDL_FreeSurface(temp)
	}
	
	/* Set transparent pixel as the pixel at (0,0) */
	if transparent {
		if temp.pointee.format.pointee.BytesPerPixel == 1 {
			SDL_SetColorKey(temp, 1, Uint32(temp.pointee.pixels.assumingMemoryBound(to: Uint8.self).pointee));
		}
	}
	
	guard let texture = SDL_CreateTextureFromSurface(renderer, temp) else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create texture: %s\n", SDL_GetError())
		return nil
	}
	return texture
}

private func loadTexture(_ renderer: SDL_RendererPtr, fileURL: URL, transparent: Bool) -> SDL_TexturePtr? {
	return fileURL.withUnsafeFileSystemRepresentation({ (file) -> SDL_TexturePtr? in
		guard let file = file else {
			return nil
		}
		return loadTexture(renderer, file: file, transparent: transparent)
	})
}

func loop(_ gamecontroller: SDL_GameControllerPtr) {
	var event = SDL_Event()
	
	/* blank screen, set up for drawing this frame. */
	SDL_SetRenderDrawColor(screen, 0xFF, 0xFF, 0xFF, SDL_ALPHA_OPAQUE);
	SDL_RenderClear(screen);
	SDL_RenderCopy(screen, background, nil, nil);

	while (SDL_PollEvent(&event) != 0) {
		switch event.type {
		case .CONTROLLERAXISMOTION:
			SDL_Log("Controller axis %s changed to %d\n", SDL_GameControllerGetStringForAxis(event.caxis.axis), event.caxis.value);
			
		case .CONTROLLERBUTTONDOWN, .CONTROLLERBUTTONUP:
			SDL_Log("Controller button %s %s\n", SDL_GameControllerGetStringForButton(event.cbutton.button), event.cbutton.state == .PRESSED ? "pressed" : "released");
			/* First button triggers a 0.5 second full strength rumble */
			if (event.type == .CONTROLLERBUTTONDOWN &&
				event.cbutton.button == .a) {
				SDL_GameControllerRumble(gamecontroller, 0xFFFF, 0xFFFF, 500);
			}

			
		case .KEYDOWN:
			if (event.key.keysym.sym != SDLK_ESCAPE) {
				break;
			}
			fallthrough
			
		case .QUIT:
			done = true
			
		default:
			break
		}
	}
	
	/* Update visual controller state */
	for i in 0 ..< SDL_GameControllerButton.CONTROLLER_BUTTON_MAX.rawValue {
		if (SDL_GameControllerGetButton(gamecontroller, SDL_GameControllerButton(rawValue: i)!) == SDL_EventStateGeneric.PRESSED.rawValue) {
			var dst = SDL_Rect(x: buttonPositions[Int(i)].x, y: buttonPositions[Int(i)].y, w: 50, h: 50 );
			SDL_RenderCopyEx(screen, button, nil, &dst, 0, nil, []);
		}
	}
	
	for i in 0 ..< SDL_GameControllerAxis.CONTROLLER_AXIS_MAX.rawValue {
		let deadzone: Sint16 = 8000;  /* !!! FIXME: real deadzone */
		let value = SDL_GameControllerGetAxis(gamecontroller, SDL_GameControllerAxis(rawValue: i)!);
		if value < -deadzone {
			var dst = SDL_Rect(x: AxisPositions[Int(i)].x, y: AxisPositions[Int(i)].y, w: 50, h: 50)
			let angle = AxisPositions[Int(i)].angle;
			SDL_RenderCopyEx(screen, axis, nil, &dst, angle, nil, []);
		} else if value > deadzone {
			var dst = SDL_Rect(x: AxisPositions[Int(i)].x, y: AxisPositions[Int(i)].y, w: 50, h: 50);
			let angle = AxisPositions[Int(i)].angle + 180.0;
			SDL_RenderCopyEx(screen, axis, nil, &dst, angle, nil, []);
		}
	}
	
	SDL_RenderPresent(screen);
	
	if (!SDL_GameControllerGetAttached(gamecontroller).boolValue) {
		done = true
		retval = true  /* keep going, wait for reattach. */
	}
}

private func watchGameController(_ gamecontroller: SDL_GameControllerPtr) -> Bool {
	let name = SDL_GameControllerName(gamecontroller)
	var basetitle = "Game Controller Test: "
	
	if let name = name {
		basetitle += String(cString: name)
	}
	
	guard let window: SDL_WindowPtr = SDL_CreateWindow(basetitle, Int32(SDL_WINDOWPOS_CENTERED), Int32(SDL_WINDOWPOS_CENTERED), SCREEN_WIDTH, SCREEN_HEIGHT, [.allowHighDPI]) else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create window: %s\n", SDL_GetError());
		return false
	}
	defer {
		SDL_DestroyWindow(window)
	}
	
	screen = SDL_CreateRenderer(window, -1, [.accelerated])
	guard let screen = screen else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create renderer: %s\n", SDL_GetError());
		return false
	}
	defer {
		SDL_DestroyRenderer(screen)
	}
	
	SDL_SetRenderDrawColor(screen, 0x00, 0x00, 0x00, SDL_ALPHA_OPAQUE);
	SDL_RenderClear(screen);
	SDL_RenderPresent(screen);
	SDL_RaiseWindow(window);
	
	/* scale for platforms that don't give you the window size you asked for. */
	SDL_RenderSetLogicalSize(screen, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	background = loadTexture(screen, file: "controllermap.bmp", transparent: false)
	button = loadTexture(screen, file: "button.bmp", transparent: true)
	axis = loadTexture(screen, file: "axis.bmp", transparent: true)
	
	if background == nil || button == nil || axis == nil {
		return false;
	}
	SDL_SetTextureColorMod(button, 10, 255, 21);
	SDL_SetTextureColorMod(axis, 10, 255, 21);

	while !done {
		loop(gamecontroller);
	}
	SwiftTest_GameController.screen = nil;
	background = nil;
	button = nil;
	axis = nil;
	
	return retval.boolValue
}

private func theMainFunc() -> Int32 {
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, .info)
	
	var retcode: Int32 = 0
	var nController: Int32 = 0;
	var guid = [Int8](repeating: 0, count: 64)
	var gamecontroller: SDL_GameControllerPtr? = nil
	let ourInitFlags: SDL_InitFlags = [.video, .joystick, .gameController]

	/* Initialize SDL (Note: video is required to start event loop) */
	guard SDL_Init(ourInitFlags) >= 0 else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError());
		return 1
	}
	defer {
		SDL_QuitSubSystem(ourInitFlags)
	}
	
	SDL_GameControllerAddMappingsFromFile("gamecontrollerdb.txt")
	
	/* Print information about the mappings */
	if CommandLine.arguments.count == 1 {
		SDL_Log("Supported mappings:\n");
		for i in 0 ..< SDL_GameControllerNumMappings() {
			if let mapping = SDL_GameControllerMappingForIndex(i) {
				SDL_Log("\t%s\n", mapping);
				SDL_free(mapping);
			}
		}
		SDL_Log("\n");
	}
	
	/* Print information about the controller */
	for i in 0 ..< SDL_NumJoysticks() {
		var name: UnsafePointer<Int8>?
		var description: String
		
		SDL_JoystickGetGUIDString(SDL_JoystickGetDeviceGUID(i), &guid, Int32(guid.count))
		
		if SDL_IsGameController(i).boolValue {
			nController += 1
			name = SDL_GameControllerNameForIndex(i)
			description = "Controller"
		} else {
			name = SDL_JoystickNameForIndex(i)
			description = "Joystick"
		}
		guid.withUnsafeMutableBufferPointer { (uuid) -> Void in
			SDL_Log("\(description) %d: %s (guid %s, VID 0x%.4x, PID 0x%.4x)\n",
				i, name ?? "Unknown", uuid.baseAddress!,
				SDL_JoystickGetDeviceVendor(i), SDL_JoystickGetDeviceProduct(i))
		}
	}
	SDL_Log("There are %d game controller(s) attached (%d joystick(s))\n", nController, SDL_NumJoysticks())

	if CommandLine.arguments.count > 1 {
		var reportederror = false
		var keepGoing = true
		var event = SDL_Event()
		let device = Int32(CommandLine.arguments[1]) ?? 0
		if device >= SDL_NumJoysticks() {
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%i is an invalid joystick index.\n", device);
			retcode = 1;
		} else {
			SDL_JoystickGetGUIDString(SDL_JoystickGetDeviceGUID(device),
									  &guid, Int32(guid.count));
			guid.withUnsafeMutableBufferPointer { (uuid) -> Void in
				SDL_Log("Attempting to open device %i, guid %s\n", device, uuid.baseAddress!);
			}
			gamecontroller = SDL_GameControllerOpen(device)
			
			if let gamecontroller = gamecontroller {
				assert(SDL_GameControllerFromInstanceID(SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(gamecontroller))) == gamecontroller)
			}
			
			while keepGoing {
				if let gamecontroller = gamecontroller {
					reportederror = false
					keepGoing = watchGameController(gamecontroller)
					SDL_GameControllerClose(gamecontroller)
				} else {
					if !reportederror {
						SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't open gamecontroller %d: %s\n", device, SDL_GetError())
						retcode = 1
						keepGoing = false
						reportederror = true
					}
				}
				
				gamecontroller = nil;
				if keepGoing {
					SDL_Log("Waiting for attach\n");
				}
				while keepGoing {
					SDL_WaitEvent(&event);
					if (event.type == .QUIT) || (event.type == .FINGERDOWN)
						|| (event.type == .MOUSEBUTTONDOWN) {
						keepGoing = false
					} else if event.type == .CONTROLLERDEVICEADDED {
						gamecontroller = SDL_GameControllerOpen(event.cdevice.which);
						if gamecontroller != nil {
							assert(SDL_GameControllerFromInstanceID(SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(gamecontroller))) == gamecontroller)
						}
						break;
					}
				}
			}
		}
	}
	
	return retcode
}

//SDL_LogSetOutputFunction(osLogOutput, nil)
SDL_LogSetOutputFunction({ (_, category, priority, message) in
	guard let message = message else {
		return
	}
	
	let swiftMessage = String(cString: message)
	let priorityName: String
	switch priority {
	case .verbose:
		priorityName = "Verbose"
		
	case .debug:
		priorityName = "Debug"
		
	case .info:
		priorityName = "Info"
		
	case .warn:
		priorityName = "Warn"
		
	case .error:
		priorityName = "Error"
		
	case .critical:
		priorityName = "Critical"
		
	default:
		priorityName = "Unknown"
	}
	
	print("[\(priorityName)] \(swiftMessage)")
}, nil)

let retCode = theMainFunc()
exit(retCode)
