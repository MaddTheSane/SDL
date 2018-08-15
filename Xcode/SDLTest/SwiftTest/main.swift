//
//  main.swift
//  SDLTest
//
//  Created by C.W. Betts on 2/1/16.
//
//

import Foundation
import SDL2
import SDL2.SDL_shape

private let screenWidth: Int32 = 512
private let screenHeight: Int32 = 317

private let MAP_WIDTH = 512
private let MAP_HEIGHT = 317

enum MapMarker {
  case button
  case axis
}

private func loadTexture(_ renderer: SDL_RendererPtr, file: UnsafePointer<Int8>, transparent: Bool) -> SDL_TexturePtr? {
	var temp: UnsafeMutablePointer<SDL_Surface>? = nil
	/* Load the sprite image */
	temp = SDL_LoadBMP(file);
	if temp == nil {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't load %s: %s", file, SDL_GetError());
		return nil;
	}

	/* Set transparent pixel as the pixel at (0,0) */
	if transparent {
		if temp?.pointee.format.pointee.palette != nil {
			SDL_SetColorKey(temp, 1, UInt32((temp?.pointee.pixels)!.assumingMemoryBound(to: UInt8.self).pointee))
		} else {
			switch (temp?.pointee.format.pointee.BitsPerPixel)! {
			case 15:
				SDL_SetColorKey(temp, 1,
					UInt32((temp!.pointee.pixels).assumingMemoryBound(to: UInt16.self).pointee & 0x00007FFF))

			case 16:
				SDL_SetColorKey(temp, 1,
					UInt32((temp!.pointee.pixels).assumingMemoryBound(to: UInt16.self).pointee))

			case 24:
				SDL_SetColorKey(temp, 1,
					(temp!.pointee.pixels).assumingMemoryBound(to: UInt32.self).pointee & 0x00FFFFFF)

			case 32:
				SDL_SetColorKey(temp, 1, (temp!.pointee.pixels).assumingMemoryBound(to: UInt32.self).pointee)
				
			default:
				SDL_LogError(Int32(SDL_LOG_CATEGORY_APPLICATION), "Unknown bits per pixels: %d", temp!.pointee.format.pointee.BitsPerPixel)
				SDL_FreeSurface(temp)
				return nil
			}
		}
	}
	
	/* Create textures from the image */
	guard let texture = SDL_CreateTextureFromSurface(renderer, temp) else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create texture: %s\n", SDL_GetError())
		SDL_FreeSurface(temp)
		return nil
	}
	SDL_FreeSurface(temp)
	
	/* We're ready to roll. :) */
	return texture
}

private func watchJoystick(_ joystick: OpaquePointer) -> Bool {
	struct MappingStep {
		var x: Int32
		var y: Int32
		var angle: Double
		var marker: MapMarker
		var field: String
		var axis: Uint8?
		var button: Uint8?
		var hat: Uint8?
		var hat_value: SDL_HatPosition?
		var mapping: String
	}
	var steps: [MappingStep] = [
		MappingStep(x: 342, y: 132,  angle: 0.0,  marker: MapMarker.button, field: "x", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 387, y: 167,  angle: 0.0,  marker: MapMarker.button, field: "a", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 431, y: 132,  angle: 0.0,  marker: MapMarker.button, field: "b", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 389, y: 101,  angle: 0.0,  marker: MapMarker.button, field: "y", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 174, y: 132,  angle: 0.0,  marker: MapMarker.button, field: "back", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 233, y: 132,  angle: 0.0,  marker: MapMarker.button, field: "guide", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 289, y: 132,  angle: 0.0,  marker: MapMarker.button, field: "start", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 116, y: 217,  angle: 0.0,  marker: MapMarker.button, field: "dpleft", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 154, y: 249,  angle: 0.0,  marker: MapMarker.button, field: "dpdown", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 186, y: 217,  angle: 0.0,  marker: MapMarker.button, field: "dpright", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 154, y: 188,  angle: 0.0,  marker: MapMarker.button, field: "dpup", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 77,  y: 40,   angle: 0.0,  marker: MapMarker.button, field: "leftshoulder", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 91, y: 0,    angle: 0.0,  marker: MapMarker.button, field: "lefttrigger", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 396, y: 36,   angle: 0.0,  marker: MapMarker.button, field: "rightshoulder", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 375, y: 0,    angle: 0.0,  marker: MapMarker.button, field: "righttrigger", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 75,  y: 154,  angle: 0.0,  marker: MapMarker.button, field: "leftstick", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 305, y: 230,  angle: 0.0,  marker: MapMarker.button, field: "rightstick", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 75,  y: 154,  angle: 0.0,  marker: MapMarker.axis,   field: "leftx", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 75,  y: 154,  angle: 90.0, marker: MapMarker.axis,   field: "lefty", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 305, y: 230,  angle: 0.0,  marker: MapMarker.axis,   field: "rightx", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: ""),
		MappingStep(x: 305, y: 230,  angle: 90.0, marker: MapMarker.axis,   field: "righty", axis: nil, button: nil, hat: nil, hat_value: nil, mapping: "")
	];
	
	var name: String?
	let retVal = false
	var done = false
	var next = false
	var s = 0

	var alpha: UInt8 = 200
	var alpha_step = UInt8(bitPattern: -1)
	var alpha_ticks: Uint32 = 0;
	var dst = SDL_Rect()
	var event = SDL_Event()
	
	var background: SDL_TexturePtr? = nil
	var button: SDL_TexturePtr? = nil
	var axis: SDL_TexturePtr? = nil
	var marker: SDL_TexturePtr? = nil
	var temp = [Int8](repeating: 0, count: 400)
	var mapping = ""

	/* Create a window to display joystick axis position */
	let window = SDL_CreateWindow("Game Controller Map", Int32(bitPattern: SDL_WINDOWPOS_CENTERED),
	                              Int32(bitPattern: SDL_WINDOWPOS_CENTERED), screenWidth,
		screenHeight, []);
	if window == nil {
		SDL_LogError(Int32(SDL_LOG_CATEGORY_APPLICATION), "Couldn't create window: %s\n", SDL_GetError());
		return false;
	}

	guard let screen = SDL_CreateRenderer(window, -1, []) else {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create renderer: %s\n", SDL_GetError());
		SDL_DestroyWindow(window);
		return false;
	}
	
	background = loadTexture(screen, file: "controllermap.bmp", transparent: false);
	button = loadTexture(screen, file: "button.bmp", transparent: true);
	axis = loadTexture(screen, file: "axis.bmp", transparent: true);
	SDL_RaiseWindow(window);
	
	/* scale for platforms that don't give you the window size you asked for. */
	SDL_RenderSetLogicalSize(screen, screenWidth, screenHeight);
	
	/* Print info about the joystick we are watching */
	name = String(cString: SDL_JoystickName(joystick))
	SDL_Log("Watching joystick \(SDL_JoystickInstanceID(joystick)): (\(name ?? "Unknown Joystick"))\n")
	SDL_Log("Joystick has %d axes, %d hats, %d balls, and %d buttons\n",
		SDL_JoystickNumAxes(joystick), SDL_JoystickNumHats(joystick),
		SDL_JoystickNumBalls(joystick), SDL_JoystickNumButtons(joystick));

	SDL_Log("\n\n" +
		"====================================================================================\n" +
		"Press the buttons on your controller when indicated\n" +
		"(Your controller may look different than the picture)\n" +
		"If you want to correct a mistake, press backspace or the back button on your device\n" +
		"To skip a button, press SPACE or click/touch the screen\n" +
		"To exit, press ESC\n" +
		"====================================================================================\n");

	/* Initialize mapping with GUID and name */
	SDL_JoystickGetGUIDString(SDL_JoystickGetGUID(joystick), &temp, Int32(temp.count));
	mapping = "\(String(cString: temp)),\(name ?? "Unknown Joystick"),platform:\(String(cString: SDL_GetPlatform())),"
	
	/* Loop, getting joystick events! */
	s = 0
	while s < steps.count && !done {
		/* blank screen, set up for drawing this frame. */
		let step = withUnsafeMutablePointer(to: &steps[s], { (aT) -> UnsafeMutablePointer<MappingStep> in
			return aT
		})
		step.pointee.mapping = mapping
		step.pointee.axis = nil
		step.pointee.button = nil
		step.pointee.hat = nil
		step.pointee.hat_value = nil
		
		switch(step.pointee.marker) {
		case .axis:
			marker = axis
			
		case .button:
			marker = button;
		}
		
		dst.x = step.pointee.x;
		dst.y = step.pointee.y;
		SDL_QueryTexture(marker, nil, nil, &dst.w, &dst.h);
		next=false;
		
		SDL_SetRenderDrawColor(screen, 0xFF, 0xFF, 0xFF, UInt8(SDL_ALPHA_OPAQUE))
		
		while !done && !next {
			let aTick = SDL_GetTicks() - alpha_ticks
			if aTick > 5  {
				alpha_ticks = SDL_GetTicks();
				alpha = alpha &+ alpha_step
				if alpha == 255 {
					alpha_step = UInt8(bitPattern: -1)
				}
				if alpha < 128 {
					alpha_step = 1;
				}
			}
			
			SDL_RenderClear(screen);
			SDL_RenderCopy(screen, background, nil, nil);
			SDL_SetTextureAlphaMod(marker, alpha);
			SDL_SetTextureColorMod(marker, 10, 255, 21);
			SDL_RenderCopyEx(screen, marker, nil, &dst, step.pointee.angle, nil, []);
			SDL_RenderPresent(screen);
			var _s: Int = 0

			if SDL_PollEvent(&event) != 0 {
				switch event.type {
				case .JOYAXISMOTION:
					if ((event.jaxis.value > 20000 || event.jaxis.value < -20000) && event.jaxis.value != -32768) {
						_s = 0
						while _s < s {
							if steps[_s].axis == event.jaxis.axis {
								break;
							}
							_s += 1
						}
						if _s == s {
							step.pointee.axis = event.jaxis.axis
							mapping += step.pointee.field + ":a\(event.jaxis.axis),"
							s += 1;
							next=true;
						}
					}
					
				case .JOYHATMOTION:
					if event.jhat.value == [] {
						break;  /* ignore centering, we're probably just coming back to the center from the previous item we set. */
					}
					_s = 0
					while _s < s {
						if steps[_s].hat == event.jhat.hat && steps[_s].hat_value == event.jhat.value {
							break;
						}
						_s += 1
					}
					if _s == s {
						step.pointee.hat = event.jhat.hat
						step.pointee.hat_value = event.jhat.value
						mapping += "\(step.pointee.field):h\(event.jhat.hat).\(event.jhat.value.rawValue),"
						s += 1;
						next=true;
					}

				case .JOYBALLMOTION:
					break;
					
				case .JOYBUTTONUP:
					while _s < s {
						if steps[_s].button == event.jbutton.button {
							break;
						}
						_s += 1
					}
					if _s == s {
						step.pointee.button = event.jbutton.button
						mapping += step.pointee.field + ":b\(event.jbutton.button),"
						s += 1;
						next=true;
					}
					
				case .FINGERDOWN,  .MOUSEBUTTONDOWN:
					/* Skip this step */
					s += 1;
					next=true;

				case .KEYDOWN:
					if event.key.keysym.sym == SDLK_BACKSPACE || event.key.keysym.sym == SDLK_AC_BACK {
						/* Undo! */
						if (s > 0) {
							s -= 1
							let prev_step = steps[s];
							mapping = prev_step.mapping
							next = true;
						}
						break;
					}
					if event.key.keysym.sym == SDLK_SPACE {
						/* Skip this step */
						s += 1;
						next=true;
						break;
					}
					
					if event.key.keysym.sym != SDLK_ESCAPE {
						break;
					}
					fallthrough
					/* Fall through to signal quit */
				case .QUIT:
					done = true;

				default:
					break;
				}
			}
		}
		s += 1
	}
	
	if s == steps.count {
		SDL_Log("Mapping:\n\n" + mapping + "\n\n");
		/* Print to stdout as well so the user can cat the output somewhere */
		print(mapping)
	}
	
	while(SDL_PollEvent(&event) != 0) {};
	
	SDL_DestroyRenderer(screen);
	SDL_DestroyWindow(window);
	return retVal;

}

var joystick: OpaquePointer? = nil

/* Enable standard application logging */
SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, .info);

/* Initialize SDL (Note: video is required to start event loop) */
if (SDL_Init([.video, .joystick]) < 0) {
	SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError());
	exit(1);
}

/* Print information about the joysticks */
SDL_Log("There are %d joysticks attached\n", SDL_NumJoysticks());
for i in 0..<SDL_NumJoysticks() {
	let name = SDL_JoystickNameForIndex(i)
	SDL_Log("Joystick %d: %s\n", i, name ?? "Unknown Joystick")
	joystick = SDL_JoystickOpen(i)
	if (joystick == nil) {
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_JoystickOpen(%d) failed: %s\n", i,
			SDL_GetError())
	} else {
		var guid = [Int8](repeating: 0, count: 33)
		SDL_JoystickGetGUIDString(SDL_JoystickGetGUID(joystick),
			&guid, Int32(guid.count));
		//var guidPtr = UnsafePointer(guid)
		SDL_Log("       axes: %d\n", SDL_JoystickNumAxes(joystick));
		SDL_Log("      balls: %d\n", SDL_JoystickNumBalls(joystick));
		SDL_Log("       hats: %d\n", SDL_JoystickNumHats(joystick));
		SDL_Log("    buttons: %d\n", SDL_JoystickNumButtons(joystick));
		SDL_Log("instance id: %d\n", SDL_JoystickInstanceID(joystick));
		SDL_Log("       guid: %s\n", guid.withUnsafeBufferPointer({ (hi) -> UnsafePointer<CChar> in
			return hi.baseAddress!
		}));
		SDL_JoystickClose(joystick);
	}
}

if CommandLine.arguments.count > 1 {
	var reportederror = false
	var keepGoing = true
	var event = SDL_Event()
	let device = Int32(CommandLine.arguments[1]) ?? 0
	joystick = SDL_JoystickOpen(device)
	
	while keepGoing {
		if joystick == nil {
			if !reportederror {
				SDL_Log("Couldn't open joystick %d: %s\n", device, SDL_GetError())
				keepGoing = false
				reportederror = true
			}
		} else {
			reportederror = false
			keepGoing = watchJoystick(joystick!)
			SDL_JoystickClose(joystick)
		}
		
		joystick = nil
		if keepGoing {
			SDL_Log("Waiting for attach\n")
		}
		while keepGoing {
			SDL_WaitEvent(&event);
			if (event.type == .QUIT) || (event.type == .FINGERDOWN)
				|| (event.type == .MOUSEBUTTONDOWN) {
					keepGoing = false
			} else if event.type == .JOYDEVICEADDED {
				joystick = SDL_JoystickOpen(device)
				break
			}
		}
	}
} else {
	SDL_Log("\n\nUsage: ./controllermap number\nFor example: ./controllermap 0\nOr: ./controllermap 0 >> gamecontrollerdb.txt")
}

//SDL_Quit()
SDL_QuitSubSystem([.video, .joystick])

exit(0)
