#!/usr/bin/swift
import CoreGraphics
import ImageIO
import Foundation

let S = CGFloat(1024)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// 1. 透明底
ctx.clear(CGRect(x:0,y:0,width:S,height:S))

// 2. Squircle 裁剪
ctx.addPath(CGPath(roundedRect: CGRect(x:0,y:0,width:S,height:S),
                   cornerWidth:230, cornerHeight:230, transform:nil))
ctx.clip()

// 3. 背景渐变
let g = CGGradient(colorsSpace: cs, colors: [
    CGColor(colorSpace:cs, components:[0.102,0.122,0.227,1])!,
    CGColor(colorSpace:cs, components:[0.059,0.204,0.376,1])!
] as CFArray, locations:[0,1])!
ctx.drawLinearGradient(g, start:CGPoint(x:0,y:S), end:CGPoint(x:S,y:0), options:[])

// 4. 锁头
let white   = CGColor(colorSpace:cs, components:[1,1,1,1])!
let darkBlu = CGColor(colorSpace:cs, components:[0.06,0.16,0.28,1])!
let shad    = CGColor(colorSpace:cs, components:[0,0,0,0.35])!

// CG 坐标：y=0 在底部，y 向上
// 布局（锁体 + 锁扣垂直居中于 512）:
//   锁体: y 230-590 (高360), x 295-729 (宽434)
//   锁扣腿: x=415, x=609 (插入锁体内)
//   锁扣半圆: center(512, 700), r=97 → 顶点 y=797
//   垂直范围: 230~797, 中心=(230+797)/2=513 ≈ 512 ✓

let bodyBottom  = CGFloat(230)
let bodyTop     = CGFloat(590)
let bodyLeft    = CGFloat(295)
let bodyRight   = CGFloat(729)
let legLeft     = CGFloat(415)    // 锁扣左腿 x
let legRight    = CGFloat(609)    // 锁扣右腿 x
let legBottom   = CGFloat(550)    // 腿插入锁体内的底端（被锁体盖住）
let arcCenterY  = CGFloat(700)    // 半圆圆心 y
let arcRadius   = CGFloat(97)     // 半圆半径（= (legRight-legLeft)/2）

// ── 锁扣（先画，锁体叠上去盖住腿根）───────────────
ctx.saveGState()
ctx.setShadow(offset: CGSize(width:0, height:-10), blur:28, color:shad)
ctx.setStrokeColor(white)
ctx.setLineWidth(64)
ctx.setLineCap(.round)

// U 形路径: 左腿向上 → 半圆 → 右腿向下
let shacklePath = CGMutablePath()
shacklePath.move(to: CGPoint(x: legLeft,  y: legBottom))
shacklePath.addLine(to: CGPoint(x: legLeft,  y: arcCenterY))
// 从左腿顶 (π) 逆时针 → 顶部 (π/2) → 右腿顶 (0)  = 拱向上 ✓
shacklePath.addArc(center: CGPoint(x:512, y:arcCenterY),
                   radius: arcRadius,
                   startAngle: .pi, endAngle: 0,
                   clockwise: false)
shacklePath.addLine(to: CGPoint(x: legRight, y: legBottom))
ctx.addPath(shacklePath)
ctx.strokePath()
ctx.restoreGState()

// ── 锁体 ─────────────────────────────────────────────
ctx.saveGState()
ctx.setShadow(offset: CGSize(width:0, height:-8), blur:20, color:shad)
ctx.setFillColor(white)
ctx.addPath(CGPath(roundedRect: CGRect(x:bodyLeft, y:bodyBottom,
                                       width:bodyRight-bodyLeft,
                                       height:bodyTop-bodyBottom),
                   cornerWidth:54, cornerHeight:54, transform:nil))
ctx.fillPath()
ctx.restoreGState()

// ── 锁孔（圆 + 向下的槽）─────────────────────────────
ctx.saveGState()
ctx.setFillColor(darkBlu)
// 圆
ctx.addArc(center: CGPoint(x:512, y:435),
           radius:50, startAngle:0, endAngle:.pi*2, clockwise:false)
ctx.fillPath()
// 向下的槽（y 向下 = CG 中 y 减小）
ctx.fill(CGRect(x:490, y:310, width:44, height:128))
ctx.restoreGState()

// 5. 输出
let img  = ctx.makeImage()!
let url  = URL(fileURLWithPath:"/tmp/dirlock_icon_final.png")
let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("✅ Icon saved")
