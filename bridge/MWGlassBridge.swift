// MWGlassBridge.swift — MiniWin liquid-glass Swift bridge.
//
// Built on a cloud Mac (GitHub Actions, MwLiquidDuck repo)
// because the Linux build VM has no Swift toolchain. The
// product is libMWGlassBridge.a (arm64, iOS), linked into
// MiniWinCmp.dylib; the device supplies the Swift/SwiftUI
// runtime.
//
// The shape mirrors Plove's traced Swift side
// (GLASS-SWIFT-SPEC): the capsule view's body is ONLY
// Color.clear.glassEffect — body material .regular (2),
// selection-lens material .clear (1) — in a Capsule; no
// glassEffectID, no .interactive(), no container, no
// extra modifiers. Body and lens are separate instances.
import SwiftUI
import UIKit

public struct MWGlassCapsule: View {
    // Fixed at creation (Plove's `let`): 1 = .clear (pure /
    // lens), 2 = .regular (body). Changing style rebuilds
    // the hosted surface from the ObjC side.
    public let material: Int

    public init(material: Int) {
        self.material = material
    }

    public var body: some View {
        // Plove's traced Body type is
        // _ConditionalContent<ModifiedContent<Color,
        // glassEffect>, ModifiedContent<Color,
        // glassEffect>> — a ViewBuilder if/else with
        // one glassEffect branch per material, NOT a
        // conditional Glass value inside one modifier
        // (GLASS-SWIFT-SPEC SS1). The two shapes take
        // different view-graph paths; v90's device
        // round hung at the hosted view's first
        // layout/render with the value-conditional
        // shape, so the body now matches the traced
        // original exactly.
        if material == 1 {
            Color.clear.glassEffect(.clear, in: Capsule())
        } else {
            Color.clear.glassEffect(.regular, in: Capsule())
        }
    }
}

// Plove's HostedGlassSurface shape: a plain UIView holding
// a UIHostingController whose view is pinned to all four
// edges by constraints; host and hosting view are clear
// and non-opaque; the hosting view takes no touches; NO
// colour-scheme injection at init (that happens only in
// setPloveDark:).
@objc(MWHostedGlassSurface)
public class MWHostedGlassSurface: UIView {
    private let originalContent: MWGlassCapsule
    private let hostingController: UIHostingController<AnyView>
    private var lastScheme: ColorScheme?

    @objc public init(material: Int) {
        let content = MWGlassCapsule(material: material)
        self.originalContent = content
        self.hostingController = UIHostingController(rootView: AnyView(content))
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        let hv = hostingController.view!
        hv.translatesAutoresizingMaskIntoConstraints = false
        hv.backgroundColor = .clear
        hv.isOpaque = false
        hv.isUserInteractionEnabled = false
        addSubview(hv)
        NSLayoutConstraint.activate([
            hv.leadingAnchor.constraint(equalTo: leadingAnchor),
            hv.topAnchor.constraint(equalTo: topAnchor),
            hv.trailingAnchor.constraint(equalTo: trailingAnchor),
            hv.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("MWHostedGlassSurface is created in code only")
    }

    // Plove's setPloveDark:: store the scheme, REBUILD the
    // root view with the colour-scheme environment applied
    // to the original content, set the hosting controller's
    // override style (Dark = 2, Light = 1 in UIKit terms),
    // and ask the hosting view to relayout.
    @objc public func setPloveDark(_ dark: Bool) {
        let scheme: ColorScheme = dark ? .dark : .light
        lastScheme = scheme
        hostingController.rootView =
            AnyView(originalContent.environment(\.colorScheme, scheme))
        hostingController.overrideUserInterfaceStyle = dark ? .dark : .light
        hostingController.view.setNeedsLayout()
    }
}

// Creation bridge (Plove's PLSwiftNativeGlassBridge.
// createCapsuleWithMaterial:): below iOS 26 return an
// empty placeholder view; on 26+ wrap the capsule in the
// hosted surface. The material integer passes through
// verbatim — the ObjC C bridge maps pureGlass ? 1 : 2.
@objc(MWGlassBridge)
public class MWGlassBridge: NSObject {
    @objc public static func createCapsule(withMaterial material: Int) -> UIView {
        guard #available(iOS 26.0, *) else {
            return UIView(frame: .zero)
        }
        return MWHostedGlassSurface(material: material)
    }
}
