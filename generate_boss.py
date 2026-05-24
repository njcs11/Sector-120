from PIL import Image, ImageDraw
import math, os

os.makedirs("assets", exist_ok=True)

T = (0,0,0,0)

# ── BOSS KRAKEN (120x120) ─────────────────────────────────────────
def make_boss():
    W, H = 120, 120
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)

    # Body core
    d.ellipse([20,10,100,85], fill=(60,0,100,255), outline=(120,0,200,255), width=3)
    d.ellipse([28,18,92,76], fill=(80,0,130,255))

    # Glowing eye sockets
    for ex, ey in [(35,30),(55,22),(75,30)]:
        d.ellipse([ex-10,ey-10,ex+10,ey+10], fill=(20,0,40,255), outline=(180,0,255,255), width=2)
        d.ellipse([ex-6,ey-6,ex+6,ey+6], fill=(255,30,30,255))
        d.ellipse([ex-3,ey-3,ex+3,ey+3], fill=(255,200,0,255))
        d.ellipse([ex-1,ey-2,ex+1,ey+0], fill=(255,255,255,255))

    # Mouth with fangs
    d.arc([30,55,90,80], 0, 180, fill=(180,0,255,255), width=3)
    for fx in [38,50,62,74]:
        d.polygon([(fx,68),(fx+4,68),(fx+2,78)], fill=(255,255,255,255))

    # Crown spikes
    for i, (sx, sy, sh) in enumerate([(25,12,20),(40,5,28),(60,2,32),(80,5,28),(95,12,20)]):
        col = (140,0,220,255) if i%2==0 else (200,50,255,255)
        d.polygon([(sx-6,sy+sh),(sx+6,sy+sh),(sx,sy)], fill=col, outline=(255,100,255,255))

    # Tentacles (8 of them)
    tentacle_bases = [(20,80),(32,88),(45,92),(58,95),(72,95),(85,92),(98,88),(110,80)]
    for i,(tx,ty) in enumerate(tentacle_bases):
        wave = 1 if i%2==0 else -1
        pts = []
        for s in range(8):
            px = tx + wave * int(10*math.sin(s*0.8)) + (i-4)*2
            py = ty + s*5
            pts.append((px,py))
        for j in range(len(pts)-1):
            thick = max(1, 5-j//2)
            d.line([pts[j],pts[j+1]], fill=(100,0,160,255), width=thick)
        # Sucker tip
        ex,ey = pts[-1]
        d.ellipse([ex-4,ey-4,ex+4,ey+4], fill=(255,30,30,255), outline=(255,150,0,255))

    # Aura glow
    for r in range(5,0,-1):
        alpha = 20*r
        d.ellipse([20-r,10-r,100+r,85+r], outline=(150,0,255,alpha), width=2)

    img.save("assets/boss.png")
    print("  ✓ boss.png")

# ── BOSS HEALTHBAR BG (300x20) ────────────────────────────────────
def make_boss_hb():
    img = Image.new("RGBA", (300,24), T)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0,0,299,23], radius=6, fill=(30,0,50,220), outline=(180,0,255,255), width=2)
    img.save("assets/boss_hb_bg.png")
    print("  ✓ boss_hb_bg.png")

# ── BAZOOKA PICKUP (40x18) ────────────────────────────────────────
def make_bazooka():
    img = Image.new("RGBA", (40,18), T)
    d = ImageDraw.Draw(img)
    # Tube body
    d.rounded_rectangle([0,4,32,14], radius=3, fill=(60,60,70,255), outline=(120,120,140,255))
    # Barrel
    d.rectangle([30,6,39,12], fill=(40,40,50,255))
    d.rectangle([30,7,39,11], fill=(80,80,90,255))
    # Handle
    d.rectangle([8,12,13,17], fill=(50,40,30,255))
    # Scope
    d.rectangle([15,2,22,5], fill=(80,80,100,255))
    # Warning stripe
    d.rectangle([4,5,7,13], fill=(255,200,0,255))
    d.rectangle([24,5,27,13], fill=(255,200,0,255))
    # Glow
    d.ellipse([1,5,5,13], fill=(50,220,120,200))
    img.save("assets/bazooka_pickup.png")
    print("  ✓ bazooka_pickup.png")

# ── ROCKET / BAZOOKA BULLET (24x10) ──────────────────────────────
def make_rocket():
    img = Image.new("RGBA", (24,10), T)
    d = ImageDraw.Draw(img)
    # Body
    d.rounded_rectangle([4,2,22,8], radius=2, fill=(180,60,20,255))
    # Nose
    d.polygon([(22,5),(28,2),(28,8)], fill=(220,80,30,255))
    # Fins
    d.polygon([(4,5),(0,1),(6,5)], fill=(140,40,10,255))
    d.polygon([(4,5),(0,9),(6,5)], fill=(140,40,10,255))
    # Exhaust
    d.ellipse([0,3,6,7], fill=(255,150,50,180))
    img.save("assets/rocket.png")
    print("  ✓ rocket.png")

# ── BOSS SPIRAL BULLET (12x12) ────────────────────────────────────
def make_spiral_bullet():
    img = Image.new("RGBA", (12,12), T)
    d = ImageDraw.Draw(img)
    d.ellipse([1,1,11,11], fill=(180,0,255,255), outline=(255,100,255,255), width=1)
    d.ellipse([3,3,9,9], fill=(255,50,255,255))
    d.ellipse([5,5,7,7], fill=(255,255,255,255))
    img.save("assets/boss_spiral.png")
    print("  ✓ boss_spiral.png")

# ── BOSS LASER SEGMENT (8x8) ──────────────────────────────────────
def make_laser():
    img = Image.new("RGBA", (8,8), T)
    d = ImageDraw.Draw(img)
    d.rectangle([0,2,7,5], fill=(255,30,30,255))
    d.rectangle([1,3,6,4], fill=(255,200,200,255))
    img.save("assets/boss_laser.png")
    print("  ✓ boss_laser.png")

# ── BOSS MISSILE (20x8) ───────────────────────────────────────────
def make_missile():
    img = Image.new("RGBA", (20,8), T)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,1,17,6], radius=2, fill=(200,50,50,255))
    d.polygon([(17,4),(22,1),(22,7)], fill=(220,80,80,255))
    d.polygon([(2,4),(0,1),(4,4)], fill=(160,30,30,255))
    d.polygon([(2,4),(0,7),(4,4)], fill=(160,30,30,255))
    d.ellipse([0,2,4,5], fill=(255,100,50,200))
    img.save("assets/boss_missile.png")
    print("  ✓ boss_missile.png")

if __name__ == "__main__":
    print("Generating boss assets...")
    make_boss()
    make_boss_hb()
    make_bazooka()
    make_rocket()
    make_spiral_bullet()
    make_laser()
    make_missile()
    print("Done!")
