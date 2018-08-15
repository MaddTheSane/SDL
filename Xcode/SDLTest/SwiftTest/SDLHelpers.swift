//
//  SDLHelpers.swift
//  SDLTest
//
//  Created by C.W. Betts on 2/1/16.
//
//

import Foundation
import SDL2
import SDL2.SDL_shape

/*
public var SDL_AUDIO_MASK_BITSIZE: Int32 { get }
public var SDL_AUDIO_MASK_DATATYPE: Int32 { get }
public var SDL_AUDIO_MASK_ENDIAN: Int32 { get }
public var SDL_AUDIO_MASK_SIGNED: Int32 { get }
*/

//extension SDL_AudioFormat {
//	var bitSize: UInt8 {
//		return UInt8(self.rawValue & SDL_AUDIO_MASK_BITSIZE.rawValue)
//	}
//}

//MARK: - log

/// Log a message with `SDL_LOG_PRIORITY_ERROR`
func SDL_LogError(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(category, .error, outStr, blankVAList)
}

func SDL_Log(_ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .info, outStr, blankVAList)
}

/// Log a message with `SDL_LOG_PRIORITY_VERBOSE`
func SDL_LogVerbose(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .verbose, outStr, blankVAList)
}

/// Log a message with `SDL_LOG_PRIORITY_DEBUG`
func SDL_LogDebug(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .debug, outStr, blankVAList)
}

/// Log a message with `SDL_LOG_PRIORITY_INFO`
func SDL_LogInfo(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .info, outStr, blankVAList)
}

/// Log a message with `SDL_LOG_PRIORITY_WARN`
func SDL_LogWarn(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .warn, outStr, blankVAList)
}

/// Log a message with SDL_LOG_PRIORITY_CRITICAL
func SDL_LogCritical(_ category: Int32, _ fmt: String, _ args: CVarArg...) {
	let blankVAList = getVaList([])
	let outStr = String(format: fmt, arguments: args)
	SDL_LogMessageV(SDL_LOG_CATEGORY_APPLICATION, .critical, outStr, blankVAList)
}

// MARK: -

public func SDL_LoadWAV(_ file: UnsafePointer<CChar>, _ spec: UnsafeMutablePointer<SDL_AudioSpec>, _ audio_buf: UnsafeMutablePointer<UnsafeMutablePointer<Uint8>?>, _ audio_len: UnsafeMutablePointer<Uint32>) -> UnsafeMutablePointer<SDL_AudioSpec> {
	return SDL_LoadWAV_RW(SDL_RWFromFile(file, "rb"), 1, spec, audio_buf, audio_len)
}

@discardableResult
public func SDL_GameControllerAddMappingsFromFile(_ file: UnsafePointer<CChar>) -> Int32 {
	return SDL_GameControllerAddMappingsFromRW(SDL_RWFromFile(file, "rb"), 1)
}

typealias SDL_TexturePtr = OpaquePointer
typealias SDL_RendererPtr = OpaquePointer
typealias SDL_GameControllerPtr = OpaquePointer
typealias SDL_WindowPtr = OpaquePointer

//MARK: - rect

extension SDL_Rect: Equatable {
	/// Returns `true` if point resides inside a rectangle.
	public func pointInRect(_ p: SDL_Point) -> Bool {
		return ( (p.x >= x) && (p.x < (x + w)) &&
			(p.y >= y) && (p.y < (y + h)) ) ? true : false
	}
	
	/// Returns `true` if the rectangle has no area.
	public var isEmpty: Bool {
		return ((self.w <= 0) || (self.h <= 0)) ? true : false;
	}
	
	
	/// Determine whether two rectangles intersect.
	///
	/// - returns: `true` if there is an intersection, `false` otherwise.
	public func intersects(_ B: SDL_Rect) -> Bool {
		var ap = self
		var bp = B
		return SDL_HasIntersection(&ap, &bp).boolValue
	}
	
	/// Calculate the union of two rectangles.
	public func union(_ B: SDL_Rect) -> SDL_Rect {
		var ap = self
		var bp = B
		var result = SDL_Rect()
		SDL_UnionRect(&ap, &bp, &result)
		return result
	}
	
	public mutating func formUnion(_ B: SDL_Rect) {
		var ap = self
		var bp = B
		SDL_UnionRect(&ap, &bp, &self)
	}
	
	public static func ==(a: SDL_Rect, b: SDL_Rect) -> Bool {
		return ((a.x == b.x) && (a.y == b.y) &&
			(a.w == b.w) && (a.h == b.h)) ? true : false
	}
}

//MARK: - mutexes

public func SDL_mutexP(_ m: OpaquePointer) -> Int32 {
	return SDL_LockMutex(m)
}

public func SDL_mutexV(_ m: OpaquePointer) -> Int32 {
	return SDL_UnlockMutex(m)
}

//MARK: - pixels

public typealias SDL_Colour = SDL_Color

//MARK: - quit

public func SDL_QuitRequested() -> Bool {
	SDL_PumpEvents()
	return SDL_PeepEvents(nil, 0, .peek, .QUIT, .QUIT) > 0
}

//MARK: rwops

public func SDL_RWsize(_ ctx: UnsafeMutablePointer<SDL_RWops>) -> Int64 {
	return ctx.pointee.size(ctx)
}

public func SDL_RWseek(_ ctx: UnsafeMutablePointer<SDL_RWops>, _ offset: Int64, _ whence: Int32) -> Int64 {
	return ctx.pointee.seek(ctx, offset, whence)
}

public func SDL_RWtell(_ ctx: UnsafeMutablePointer<SDL_RWops>) -> Int64 {
	return ctx.pointee.seek(ctx, 0, RW_SEEK_CUR)
}

public func SDL_RWread(_ ctx: UnsafeMutablePointer<SDL_RWops>, _ ptr: UnsafeMutableRawPointer, _ size: Int, _ n: Int) -> Int {
	return ctx.pointee.read(ctx, ptr, size, n)
}

public func SDL_RWwrite(_ ctx: UnsafeMutablePointer<SDL_RWops>, _ ptr: UnsafeRawPointer, _ size: Int, _ n: Int) -> Int {
	return ctx.pointee.write(ctx, ptr, size, n)
}

public func SDL_RWclose(_ ctx: UnsafeMutablePointer<SDL_RWops>) -> Int32 {
	return ctx.pointee.close(ctx)
}


//MARK: - shape

extension WindowShapeMode {
	public var alpha: Bool {
		return (self == .default || self == .binarizeAlpha || self == .reverseBinarizeAlpha)
	}
}

public func SDL_SHAPEMODEALPHA(_ mode: WindowShapeMode) -> Bool {
	return mode.alpha
}

//MARK: - stdinc

extension SDL_bool: ExpressibleByBooleanLiteral {
	public init(booleanLiteral value: Bool) {
		if value == true {
			self = .TRUE
		} else {
			self = .FALSE
		}
	}
	
	public var boolValue: Bool {
		if self == .FALSE {
			return false
		} else {
			return true
		}
	}
}

//MARK: - surface

extension SDL_Surface {
	public var mustLock: Bool {
		return flags.contains(.RLEACCEL)
	}
}

public func SDL_MUSTLOCK(_ S: UnsafePointer<SDL_Surface>) -> Bool {
	return S.pointee.mustLock
}

public func SDL_LoadBMP(_ file: UnsafePointer<Int8>) -> UnsafeMutablePointer<SDL_Surface>? {
	return SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1)
}

public func SDL_SaveBMP(_ surface: UnsafeMutablePointer<SDL_Surface>, _ file: UnsafePointer<CChar>) -> Int32 {
	return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb"), 1)
}

//MARK: - timer

public func SDL_TICKS_PASSED(_ A: Uint32, _ B: Uint32) -> Bool {
	return (Int32(B) - Int32(A)) <= 0
}

#if false
///  Macro-like function to determine SDL version program was compiled against.
///
///  This macro fills in a SDL_version structure with the version of the
///  library you compiled against. This is determined by what header the
///  compiler uses. Note that if you dynamically linked the library, you might
///  have a slightly newer or older version at runtime. That version can be
///  determined with SDL_GetVersion(), which, unlike SDL_VERSION(),
///  is not a macro.
///
///  - parameter x: A pointer to a SDL_version struct to initialize.
public func SDL_VERSION(x: inout SDL_version) {
	x.major = Uint8(SDL_MAJOR_VERSION)
	x.minor = Uint8(SDL_MINOR_VERSION)
	x.patch = Uint8(SDL_PATCHLEVEL)

}
#endif

///  This function turns the version numbers into a numeric value:
///
///		(1,2,3) -> (1203)
///
///  This assumes that there will never be more than 100 patchlevels.
public func SDL_VERSIONNUM(_ X: UInt8, _ Y: UInt8, _ Z: UInt8) -> Int32 {
	return (Int32(X)*1000 + Int32(Y)*100 + Int32(Z))
}

// MARK: video:

public func SDL_WINDOWPOS_UNDEFINED_DISPLAY(_ x: UInt32) -> UInt32 {
	return SDL_WINDOWPOS_UNDEFINED_MASK | x
}

public let SDL_WINDOWPOS_UNDEFINED = SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)

public func SDL_WINDOWPOS_ISUNDEFINED(_ X: UInt32) -> Bool {
	return (X & 0xFFFF0000) == SDL_WINDOWPOS_UNDEFINED_MASK
}


public func SDL_WINDOWPOS_CENTERED_DISPLAY(_ X: UInt32) -> UInt32 {
	return SDL_WINDOWPOS_CENTERED_MASK | X
}

public let SDL_WINDOWPOS_CENTERED = SDL_WINDOWPOS_CENTERED_DISPLAY(0)

public func SDL_WINDOWPOS_ISCENTERED(_ X: UInt32) -> Bool {
	return (X & 0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK
}
