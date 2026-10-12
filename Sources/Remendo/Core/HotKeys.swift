import Carbon.HIToolbox

/// Atalhos globais via `RegisterEventHotKey`. Disparam com o Remendo em segundo plano
/// e não precisam de permissão nenhuma do macOS.
final class HotKeys {
    private var actions: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    /// Todas as instâncias recebem o mesmo evento, então os ids não podem se repetir entre elas.
    private static var nextID: UInt32 = 1
    private static let signature: OSType = 0x524D_4E44 // "RMND"

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)

            let hotKeys = Unmanaged<HotKeys>.fromOpaque(userData).takeUnretainedValue()
            guard id.signature == HotKeys.signature, let action = hotKeys.actions[id.id] else {
                // É de outra instância: deixa o próximo handler tratar.
                return OSStatus(eventNotHandledErr)
            }
            action()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    deinit {
        removeAll()
        if let handler { RemoveEventHandler(handler) }
    }

    /// Troca todos os atalhos desta instância pelos de `bindings`.
    func set(_ bindings: [(Shortcut, () -> Void)]) {
        removeAll()
        for (shortcut, action) in bindings {
            let id = Self.nextID
            Self.nextID += 1

            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.carbonModifiers,
                EventHotKeyID(signature: Self.signature, id: id),
                GetEventDispatcherTarget(),
                0,
                &ref
            )
            guard status == noErr, let ref else { continue }
            refs.append(ref)
            actions[id] = action
        }
    }

    private func removeAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs = []
        actions = [:]
    }
}
