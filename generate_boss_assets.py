from PIL import Image, ImageDraw
import math, os

os.makedirs("assets", exist_ok=True)
T = (0,0,0,0)

# ── BOSS (120x100) kraken style ──────────────────────────────────
def make_boss():
    W, H = 120, 100
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)

    # Tentacles (background layer)
    tentacle_data = [
        (10, 60, 0,  90,  18),
        (25, 65, 10, 95,  16),
        (40, 68, 30, 98,  14),
        (60, 68, 70, 98,  14),
        (75, 65, 90, 95,  16),
        (95, 60, 110,90,  18),
        (20, 62, -5, 85,  12),
        (100,62, 125,85,  12),
    ]
    for x1,y1,x2,y2,w in tentacle_data:
        d.line([(x1,y1),(x2,y2)], fill=(60,0,100,220), width=w)
        # Sucker tips
        d.ellipse([x2-6,y2-6,x2+6,y2+6], fill=(180,0,80,255))

    # Main body
    d.ellipse([15, 10, 105, 75], fill=(100, 0, 160, 255))
    d.ellipse([20, 15, 100, 70], fill=(130, 20, 190, 255))

    # Bioluminescent patterns
    for i, (x,y,r) in enumerate([(40,35,8),(60,30,6),(80,35,8),(50,50,5),(70,50,5)]):
        d.ellipse([x-r,y-r,x+r,y+r], fill=(200,100,255,180))
        d.ellipse([x-r+2,y-r+2,x+r-2,y+r-2], fill=(230,180,255,220))

    # 3 eyes (red glowing)
    for ex, ey in [(38,28),(60,22),(82,28)]:
        d.ellipse([ex-10,ey-10,ex+10,ey+10], fill=(180,0,0,255))
        d.ellipse([ex-7, ey-7, ex+7, ey+7],  fill=(255,50,50,255))
        d.ellipse([ex-4, ey-4, ex+4, ey+4],  fill=(255,200,0,255))
        d.ellipse([ex-2, ey-2, ex+2, ey+2],  fill=(255,255,255,255))

    # Mouth with teeth
    d.arc([40,45,80,70], 10, 170, fill=(20,0,40,255), width=4)
    for tx in range(45,78,7):
        d.polygon([(tx,58),(tx+3,65),(tx+6,58)], fill=(255,255,255,200))

    # Crown spikes on top
    for sx,sy in [(30,12),(45,5),(60,2),(75,5),(90,12)]:
        d.polygon([(sx-6,sy+10),(sx,sy),(sx+6,sy+10)], fill=(80,0,130,255))

    img.save("assets/boss.png")
    print("  ✓ boss.png")

# ── BAZOOKA PICKUP (40x16) ───────────────────────────────────────
def make_bazooka():
    W, H = 40, 16
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)
    # Tube body
    d.rounded_rectangle([2,4,34,12], radius=3, fill=(60,60,70,255))
    d.rounded_rectangle([3,5,33,11], radius=2, fill=(90,90,100,255))
    # Barrel
    d.ellipse([30,3,39,13], fill=(50,50,60,255))
    d.ellipse([32,5,39,11], fill=(30,30,40,255))
    # Handle
    d.rectangle([10,11,14,15], fill=(70,40,20,255))
    # Scope
    d.rectangle([15,2,22,5],  fill=(40,40,50,255))
    d.ellipse([18,1,22,5],    fill=(80,200,255,200))
    # Glow
    d.rectangle([2,4,6,12],   fill=(255,150,50,180))
    img.save("assets/bazooka_pickup.png")
    print("  ✓ bazooka_pickup.png")

# ── BAZOOKA ROCKET (24x10) ───────────────────────────────────────
def make_rocket():
    W, H = 24, 10
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)
    # Body
    d.rounded_rectangle([4,2,22,8], radius=2, fill=(180,60,0,255))
    # Nose cone
    d.polygon([(22,5),(18,2),(18,8)], fill=(220,100,20,255))
    # Fins
    d.polygon([(4,5),(0,2),(4,3)], fill=(150,50,0,255))
    d.polygon([(4,5),(0,8),(4,7)], fill=(150,50,0,255))
    # Exhaust
    d.ellipse([0,3,5,7], fill=(255,180,50,180))
    img.save("assets/rocket.png")
    print("  ✓ rocket.png")

# ── BOSS LASER (8x8 tile, drawn as beam segment) ─────────────────
def make_laser():
    W, H = 8, 8
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)
    d.ellipse([0,0,7,7], fill=(255,50,50,200))
    d.ellipse([1,1,6,6], fill=(255,180,180,255))
    d.ellipse([2,2,5,5], fill=(255,255,255,255))
    img.save("assets/boss_laser.png")
    print("  ✓ boss_laser.png")

# ── BOSS MISSILE (20x8) ──────────────────────────────────────────
def make_boss_missile():
    W, H = 20, 8
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2,1,18,7], radius=2, fill=(80,0,120,255))
    d.polygon([(18,4),(14,1),(14,7)], fill=(180,50,255,255))
    d.polygon([(2,4),(0,1),(2,3)],    fill=(60,0,90,255))
    d.polygon([(2,4),(0,7),(2,5)],    fill=(60,0,90,255))
    d.ellipse([0,2,4,6], fill=(200,100,255,180))
    img.save("assets/boss_missile.png")
    print("  ✓ boss_missile.png")

# ── SPIRAL ORB (10x10) ───────────────────────────────────────────
def make_spiral_orb():
    W, H = 10, 10
    img = Image.new("RGBA", (W, H), T)
    d = ImageDraw.Draw(img)
    d.ellipse([0,0,9,9], fill=(50,200,255,220))
    d.ellipse([2,2,7,7], fill=(150,240,255,255))
    d.ellipse([3,3,6,6], fill=(255,255,255,255))
    img.save("assets/spiral_orb.png")
    print("  ✓ spiral_orb.png")

if __name__ == "__main__":
    print("Generating boss assets...")
    make_boss()
    make_bazooka()
    make_rocket()
    make_laser()
    make_boss_missile()
    make_spiral_orb()
    print("Done!")
