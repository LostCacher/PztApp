"""Render the original vector mark at Android/web icon sizes (requires Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<defs><linearGradient id="neon" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#b28aff"/><stop offset="1" stop-color="#ff65ba"/></linearGradient></defs>
<rect width="512" height="512" rx="112" fill="#11121b"/>
<path d="M256 83 405 169 405 343 256 429 107 343 107 169Z" fill="#20192f" stroke="url(#neon)" stroke-width="17" stroke-linejoin="round"/>
<path d="M151 268H205L235 195 277 325 308 246H361" fill="none" stroke="url(#neon)" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="151" cy="268" r="13" fill="#b28aff"/><circle cx="361" cy="246" r="13" fill="#ff65ba"/>
</svg>'''

def render(size):
    scale = 4
    n = size * scale
    k = n / 512
    image = Image.new('RGB', (n, n), '#11121b')
    draw = ImageDraw.Draw(image)
    xy = lambda points: [(round(x*k), round(y*k)) for x, y in points]
    hexagon = xy([(256,83),(405,169),(405,343),(256,429),(107,343),(107,169),(256,83)])
    pulse = xy([(151,268),(205,268),(235,195),(277,325),(308,246),(361,246)])
    mask = Image.new('L', (n,n))
    pen = ImageDraw.Draw(mask)
    pen.line(hexagon, fill=255, width=max(1,round(17*k)), joint='curve')
    for x,y in hexagon:
        r=8.5*k
        pen.ellipse((x-r,y-r,x+r,y+r),fill=255)
    pen.line(pulse, fill=255, width=max(1,round(22*k)), joint='curve')
    for x,y in [pulse[0], pulse[-1]]:
        r=13*k
        pen.ellipse((x-r,y-r,x+r,y+r),fill=255)
    draw.polygon(hexagon,fill='#20192f')
    gradient = Image.new('RGB',(n,n))
    gp=ImageDraw.Draw(gradient)
    for y in range(n):
        t=y/max(1,n-1)
        color=tuple(round(a+(b-a)*t) for a,b in zip((178,138,255),(255,101,186)))
        gp.line((0,y,n,y),fill=color)
    image.paste(gradient,(0,0),mask)
    return image.resize((size,size),Image.Resampling.LANCZOS)

if __name__ == '__main__':
    (ROOT/'assets/branding/pzt-logo.svg').write_text(SVG)
    render(512).save(ROOT/'assets/branding/pzt-logo.png')
    render(32).save(ROOT/'web/favicon.png')
    for size in [192,512]:
        for prefix in ['Icon','Icon-maskable']:
            render(size).save(ROOT/f'web/icons/{prefix}-{size}.png')
    for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        render(size).save(ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
