#!/usr/bin/env python3
"""生成 DirLock app 图标 PNG（1024x1024，无 alpha 通道，无白边）"""
import struct, zlib, math

def write_png(filename, width, height, pixels):
    def row_bytes(row): return b'\x00' + row
    raw = b''.join(row_bytes(pixels[y]) for y in range(height))
    compressed = zlib.compress(raw, 9)
    def chunk(name, data):
        c = zlib.crc32(name + data) & 0xffffffff
        return struct.pack('>I', len(data)) + name + data + struct.pack('>I', c)
    with open(filename, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', compressed))
        f.write(chunk(b'IEND', b''))

SIZE = 1024
pixels = []

for y in range(SIZE):
    row = bytearray()
    for x in range(SIZE):
        # 背景渐变（深海军蓝）
        t = (x + y) / (2.0 * SIZE)
        r = int(0x1a + (0x0f - 0x1a) * t)
        g = int(0x1f + (0x34 - 0x1f) * t)
        b = int(0x3a + (0x60 - 0x3a) * t)

        # 锁身（圆角矩形 292,480 → 732,830，圆角半径 56）
        lx1, ly1, lx2, ly2, lr = 292, 480, 732, 830, 56
        in_body = (
            (lx1+lr <= x <= lx2-lr and ly1 <= y <= ly2) or
            (lx1 <= x <= lx2 and ly1+lr <= y <= ly2-lr) or
            math.hypot(x-(lx1+lr), y-(ly1+lr)) <= lr or
            math.hypot(x-(lx2-lr), y-(ly1+lr)) <= lr or
            math.hypot(x-(lx1+lr), y-(ly2-lr)) <= lr or
            math.hypot(x-(lx2-lr), y-(ly2-lr)) <= lr
        )

        # 锁扣（半圆弧，圆心 512,400，内外半径）
        dist = math.hypot(x - 512, y - 400)
        in_shackle = (114 <= dist <= 186) and y <= 490 and y >= 250

        # 锁孔
        in_hole_outer = math.hypot(x-512, y-635) <= 62
        in_hole = math.hypot(x-512, y-618) <= 28 or (496 <= x <= 528 and 630 <= y <= 678)

        if in_body or in_shackle:
            shade = int(232 - (y - 480) * 0.05) if in_body else int(252 - (y - 250) * 0.04)
            shade = max(185, min(255, shade))
            r, g, b = shade, min(255, shade + 4), min(255, shade + 18)
        if in_hole_outer and not in_hole:
            r, g, b = 26, 58, 92
        if in_hole:
            r, g, b = 13, 33, 55

        row += bytes([max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))])
    pixels.append(bytes(row))

write_png('/tmp/dirlock_icon_final.png', SIZE, SIZE, pixels)
print(f"Icon generated: /tmp/dirlock_icon_final.png ({SIZE}x{SIZE}, no alpha)")
