// dockglow — draws the "Glow glass" Dock icons and wallpaper.
// usage: dockglow batch < lines   (sym|path|symbol|hex  or  app|path|sat/white|hex)
//        dockglow wallpaper <out.png>
//        dockglow preview <out.png>     (the README image: wallpaper + a Dock of glow tiles)
import AppKit
import CoreImage
func c(_ h: Int, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: CGFloat((h>>16)&255)/255, green: CGFloat((h>>8)&255)/255, blue: CGFloat(h&255)/255, alpha: a) }
func blurred(_ im: NSImage, _ radius: CGFloat) -> NSImage {
  let pad = radius*4, sz = NSSize(width: im.size.width + pad*2, height: im.size.height + pad*2)
  let padded = NSImage(size: sz); padded.lockFocus(); im.draw(in: NSRect(x: pad, y: pad, width: im.size.width, height: im.size.height)); padded.unlockFocus()
  let rep0 = NSBitmapImageRep(data: padded.tiffRepresentation!)!
  let ci = CIImage(bitmapImageRep: rep0)!
  let f = CIFilter(name: "CIGaussianBlur")!; f.setValue(ci, forKey: kCIInputImageKey); f.setValue(radius * CGFloat(rep0.pixelsWide) / sz.width, forKey: kCIInputRadiusKey)
  let cg = CIContext().createCGImage(f.outputImage!.cropped(to: ci.extent), from: ci.extent)!
  return NSImage(cgImage: cg, size: sz)
}
func center(_ im: NSImage, _ r: NSRect) { im.draw(in: NSRect(x: r.midX - im.size.width/2, y: r.midY - im.size.height/2, width: im.size.width, height: im.size.height)) }
func glyph(app: String, mode: String, size: CGFloat) -> NSImage {
  let src = NSWorkspace.shared.icon(forFile: app); let px = 512
  func rep() -> NSBitmapImageRep { NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)! }
  let r0 = rep(); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r0)
  src.draw(in: NSRect(x: 0, y: 0, width: px, height: px)); NSGraphicsContext.restoreGraphicsState()
  let out = rep()
  for y in 0..<px { for x in 0..<px {
    let p = r0.colorAt(x: x, y: y)!
    let r = p.redComponent, g = p.greenComponent, b = p.blueComponent, a = p.alphaComponent
    let mx = max(r,g,b), mn = min(r,g,b), sat = mx == 0 ? 0 : (mx-mn)/mx
    let inner = abs(CGFloat(x - px/2)) < CGFloat(px)*0.36 && abs(CGFloat(y - px/2)) < CGFloat(px)*0.36
    var k: CGFloat = 0
    if inner && a > 0.5 { k = mode == "sat" ? min(1, max(0, (sat - 0.25) * 4)) : min(1, max(0, (mx - 0.82) * 6)) * (sat < 0.25 ? 1 : 0) }
    out.setColor(NSColor(deviceRed: 1, green: 1, blue: 1, alpha: k), atX: x, y: y)
  }}
  let im = NSImage(size: NSSize(width: size, height: size)); im.addRepresentation(out)
  let fin = NSImage(size: NSSize(width: size, height: size)); fin.lockFocus(); im.draw(in: NSRect(x: 0, y: 0, width: size, height: size)); fin.unlockFocus(); return fin
}
func sym(_ name: String, _ pt: CGFloat) -> NSImage {
  let n = NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil ? name : "folder"
  return NSImage(systemSymbolName: n, accessibilityDescription: nil)!.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pt, weight: .regular).applying(.init(paletteColors: [.white])))!
}
func tint(_ im: NSImage, _ col: NSColor) -> NSImage { let o = NSImage(size: im.size); o.lockFocus(); col.setFill(); NSRect(origin: .zero, size: im.size).fill(); im.draw(in: NSRect(origin: .zero, size: im.size), from: .zero, operation: .destinationIn, fraction: 1); o.unlockFocus(); return o }
func glassTile(_ r: NSRect, _ g: NSImage, _ glow: NSColor) {
  let rr = r.insetBy(dx: r.width*0.1, dy: r.width*0.1), rad = rr.width*0.225
  let p = NSBezierPath(roundedRect: rr, xRadius: rad, yRadius: rad)
  NSGraphicsContext.saveGraphicsState()
  let sh = NSShadow(); sh.shadowBlurRadius = r.width*0.035; sh.shadowOffset = NSSize(width: 0, height: -r.width*0.015); sh.shadowColor = NSColor.black.withAlphaComponent(0.45); sh.set()
  NSGradient(starting: c(0x2B2B31), ending: c(0x121215))!.draw(in: p, angle: -90)
  NSGraphicsContext.restoreGraphicsState()
  NSGraphicsContext.saveGraphicsState(); p.addClip()
  NSGradient(colors: [glow.withAlphaComponent(0.42), glow.withAlphaComponent(0)])!.draw(fromCenter: NSPoint(x: rr.midX, y: rr.minY), radius: 0, toCenter: NSPoint(x: rr.midX, y: rr.minY), radius: rr.width*0.85, options: [])
  NSGradient(starting: NSColor.white.withAlphaComponent(0.10), ending: NSColor.white.withAlphaComponent(0))!.draw(in: NSRect(x: rr.minX, y: rr.midY, width: rr.width, height: rr.height/2), angle: -90)
  NSGraphicsContext.restoreGraphicsState()
  let b = NSBezierPath(roundedRect: rr.insetBy(dx: r.width*0.004, dy: r.width*0.004), xRadius: rad, yRadius: rad); b.lineWidth = r.width*0.008
  NSColor.white.withAlphaComponent(0.06).setStroke(); b.stroke()
  NSGraphicsContext.saveGraphicsState(); NSBezierPath(rect: NSRect(x: rr.minX, y: rr.midY, width: rr.width, height: rr.height/2 + 2)).setClip(); NSColor.white.withAlphaComponent(0.30).setStroke(); b.stroke(); NSGraphicsContext.restoreGraphicsState()
  center(blurred(tint(g, glow), r.width*0.035), r)
  center(tint(g, NSColor.white.withAlphaComponent(0.96)), r)
}
func wallpaper(_ W: CGFloat, _ H: CGFloat) -> NSImage {
  let img = NSImage(size: NSSize(width: W, height: H)); img.lockFocus()
  NSGradient(colors: [c(0x07080D), c(0x0C0E18), c(0x080A10)])!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
  func orb(_ x: CGFloat, _ y: CGFloat, _ rad: CGFloat, _ col: NSColor) { NSGradient(colors: [col, col.withAlphaComponent(0)])!.draw(fromCenter: NSPoint(x: x, y: y), radius: 0, toCenter: NSPoint(x: x, y: y), radius: rad, options: []) }
  orb(W*0.18, H*0.78, W*0.55, c(0x5B3FD6, 0.34)); orb(W*0.86, H*0.30, W*0.50, c(0x0E7C86, 0.30))
  orb(W*0.55, H*0.02, W*0.42, c(0xC2410C, 0.20)); orb(W*0.50, H*0.55, W*0.30, c(0x1E3A8A, 0.18))
  srand48(7); for _ in 0..<Int(W*H/90) { NSColor.white.withAlphaComponent(CGFloat(drand48())*0.035).setFill(); NSRect(x: CGFloat(drand48())*W, y: CGFloat(drand48())*H, width: 1, height: 1).fill() }
  img.unlockFocus(); return img
}
let args = CommandLine.arguments
if args.count >= 3 && args[1] == "wallpaper" {
  let s = NSScreen.main!, sc = s.backingScaleFactor
  let img = wallpaper(s.frame.width*sc, s.frame.height*sc)
  let rep = NSBitmapImageRep(cgImage: img.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2])); print("wallpaper \(Int(s.frame.width*sc))x\(Int(s.frame.height*sc))")
} else if args.count >= 2 && args[1] == "batch" {
  var fails = 0
  while let line = readLine() {
    let f = line.components(separatedBy: "|"); if f.count < 4 { continue }
    let path = f[1]; guard FileManager.default.fileExists(atPath: path) else { continue }
    let col = c(Int(f[3], radix: 16) ?? 0xFFFFFF)
    let img = NSImage(size: NSSize(width: 1024, height: 1024)); img.lockFocus()
    let g = f[0] == "app" ? glyph(app: path, mode: f[2], size: 1024*0.82) : sym(f[2], 1024*0.32)
    glassTile(NSRect(x: 0, y: 0, width: 1024, height: 1024), g, col); img.unlockFocus()
    let ok = NSWorkspace.shared.setIcon(img, forFile: path, options: [])
    if !ok { fails += 1; print("BLOCKED \(path)") }
  }
  exit(fails > 0 ? 3 : 0)
} else if args.count >= 3 && args[1] == "preview" {
  // Drawn with the same functions as the real icons, so the README shows exactly what installs.
  let W: CGFloat = 2400, H: CGFloat = 640
  let tiles: [(String, Int)] = [("command", 0xA78BFA), ("bubble.left.and.bubble.right", 0x5EEAD4), ("play", 0xFDBA74),
    ("iphone", 0xE2E8F0), ("square.stack.3d.up", 0x93C5FD), ("arrow.down", 0xF0ABFC),
    ("doc.on.clipboard", 0x38BDF8), ("camera.viewfinder", 0x38BDF8), ("moon", 0x818CF8)]
  // An explicit 1x bitmap: lockFocus would render at the screen's scale.
  let out = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
  wallpaper(W, H).draw(in: NSRect(x: 0, y: 0, width: W, height: H))
  let tile: CGFloat = 200, gap: CGFloat = 8, pad: CGFloat = 26
  let dockW = CGFloat(tiles.count) * tile + CGFloat(tiles.count - 1) * gap + pad * 2 + 40, dockH = tile + pad * 2 - 40
  let dock = NSRect(x: (W - dockW) / 2, y: 110, width: dockW, height: dockH)
  let shelf = NSBezierPath(roundedRect: dock, xRadius: 44, yRadius: 44)
  NSColor.white.withAlphaComponent(0.07).setFill(); shelf.fill()
  NSColor.white.withAlphaComponent(0.14).setStroke(); shelf.lineWidth = 1.5; shelf.stroke()
  for (i, t) in tiles.enumerated() {
    let x = dock.minX + pad + 20 + CGFloat(i) * (tile + gap)
    glassTile(NSRect(x: x, y: dock.minY + 4, width: tile, height: tile), sym(t.0, tile * 0.32), c(t.1))
  }
  // the divider between stacks and the Devices shortcuts, like the real Dock's
  NSColor.white.withAlphaComponent(0.22).setFill()
  NSRect(x: dock.minX + pad + 20 + 6 * (tile + gap) - gap / 2 - 1, y: dock.minY + 40, width: 2, height: dockH - 80).fill()
  NSGraphicsContext.restoreGraphicsState()
  try! out.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2])); print("preview \(Int(W))x\(Int(H))")
} else { print("usage: dockglow batch | wallpaper <out.png> | preview <out.png>"); exit(1) }
