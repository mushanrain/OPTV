import Foundation
import AppKit
import Carbon.HIToolbox

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandler: EventHandlerRef?

    var onPressed: (() -> Void)?
    private var currentKeyCode: UInt32 = UInt32(kVK_ANSI_V)
    private var currentModifiers: UInt32 = UInt32(optionKey)

    func registerOptionV() {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, eventRef, userData) -> OSStatus in
            let hkManager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            hkManager.onPressed?()
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &hotKeyEventHandler)

        register(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(optionKey))
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = hotKeyEventHandler {
            RemoveEventHandler(handler)
            hotKeyEventHandler = nil
        }
    }

    func register(keyCode: UInt32, modifiers: UInt32) {
        currentKeyCode = keyCode
        currentModifiers = modifiers
        let hotKeyID = EventHotKeyID(signature: OSType(0x4F505456), id: 1) // 'OPTV'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func updateHotKey(letter: String, mods: [String]) {
        let code = Self.keyCode(for: letter)
        var mask: UInt32 = 0
        for m in mods {
            switch m.lowercased() {
            case "command", "cmd": mask |= UInt32(cmdKey)
            case "option", "alt": mask |= UInt32(optionKey)
            case "control", "ctrl": mask |= UInt32(controlKey)
            case "shift": mask |= UInt32(shiftKey)
            default: break
            }
        }
        unregister()
        // Reinstall handler if needed
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, eventRef, userData) -> OSStatus in
            let hkManager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            hkManager.onPressed?()
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &hotKeyEventHandler)

        register(keyCode: code, modifiers: mask)
    }

    static func keyCode(for letter: String) -> UInt32 {
        // Map common letters A-Z to kVK_ANSI_* codes
        let l = letter.lowercased()
        let mapping: [String: UInt32] = [
            "a": UInt32(kVK_ANSI_A), "b": UInt32(kVK_ANSI_B), "c": UInt32(kVK_ANSI_C),
            "d": UInt32(kVK_ANSI_D), "e": UInt32(kVK_ANSI_E), "f": UInt32(kVK_ANSI_F),
            "g": UInt32(kVK_ANSI_G), "h": UInt32(kVK_ANSI_H), "i": UInt32(kVK_ANSI_I),
            "j": UInt32(kVK_ANSI_J), "k": UInt32(kVK_ANSI_K), "l": UInt32(kVK_ANSI_L),
            "m": UInt32(kVK_ANSI_M), "n": UInt32(kVK_ANSI_N), "o": UInt32(kVK_ANSI_O),
            "p": UInt32(kVK_ANSI_P), "q": UInt32(kVK_ANSI_Q), "r": UInt32(kVK_ANSI_R),
            "s": UInt32(kVK_ANSI_S), "t": UInt32(kVK_ANSI_T), "u": UInt32(kVK_ANSI_U),
            "v": UInt32(kVK_ANSI_V), "w": UInt32(kVK_ANSI_W), "x": UInt32(kVK_ANSI_X),
            "y": UInt32(kVK_ANSI_Y), "z": UInt32(kVK_ANSI_Z)
        ]
        return mapping[l] ?? UInt32(kVK_ANSI_V)
    }
}
