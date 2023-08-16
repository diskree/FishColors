import imaged.image;

import std.algorithm;
import std.file;
import std.format;
import std.json;
import std.stdio;
import std.string;

const Pixel[] COLORS = [
    Pixel(208, 214, 215), // White
    Pixel(226, 98, 0), // Orange
    Pixel(168, 43, 158), // Magenta
    Pixel(30, 138, 200), // Light Blue
    Pixel(240, 175, 13), // Yellow
    Pixel(96, 171, 20), // Lime
    Pixel(213, 100, 142), // Pink
    Pixel(52, 56, 60), // Gray
    Pixel(126, 126, 116), // Light Gray
    Pixel(13, 120, 137), // Cyan
    Pixel(101, 26, 158), // Purple
    Pixel(41, 43, 145), // Blue
    Pixel(97, 58, 26), // Brown
    Pixel(72, 91, 31), // Green
    Pixel(144, 29, 29), // Red
    Pixel(1, 1, 1) // Black
];

void main()
{
    IMGError err;
    Image patternImg = load("in/fish.png", err);

    string path = "out/assets/minecraft/optifine/cit/fishcolors";
    mkdirRecurse(path);

    std.file.write("out/pack.mcmeta", import("pack.mcmeta"));

    int[] tags = [
        459008, 50660352, 50726144, 67108865, 67371009, 16778497, 67764993,
        918273, 917504, 918529, 67699456, 117441025, 117441793, 117506305,
        118161664, 101253888, 185008129, 234882305, 235340288, 67110144,
        117899265, 65536
    ];
    foreach (tag; tags)
    {
        uint pattern = (tag >> 8) & 0xFF;
        uint primary = (tag >> 16) & 0xFF;
        uint secondary = (tag >> 24) & 0xFF;

        writeColoredImage(patternImg, path ~ format("/%s.png", tag), COLORS[primary], COLORS[secondary]);
        std.file.write(path ~ format("/%s.properties", tag), import("stubModel.properties").format(tag, tag));
    }
}

void writeColoredImage(Image base, string outFile, Pixel primary, Pixel secondary)
{
    Image o = new Img!(Px.R8G8B8A8)(base.width, base.height);
    for (int x = 0; x < base.width; x++)
    {
        for (int y = 0; y < base.height; y++)
        {
            Pixel p = base.getPixel(x, y);
            // These are completely arbitrary I just used the eraser tool on low opacity and checked
            if (p.a == 249)
            {
                p = p.colorize(primary);
            }
            else if (p.a == 243)
            {
                p = p.colorize(secondary);
            }
            o.setPixel(x, y, p);
        }
    }
    o.write(outFile);
}

Pixel colorize(Pixel base, Pixel color)
{
    Hsl bh = base.toHsl();
    Hsl ch = color.toHsl();
    // Modifying how lightness is picked could likely provide better textures
    ch.l = (ch.l + bh.l) / 2;
    return ch.toRgb();
}

Pixel toRgb(Hsl hsl)
{
    float h = hsl.h, s = hsl.s, l = hsl.l;
    float r, g, b;
    if (s == 0)
    {
        r = l;
        g = l;
        b = l;
    }
    else
    {
        float pqt(float p, float q, float t)
        {
            if (t < 0)
            {
                t += 1;
            }
            if (t > 1)
            {
                t -= 1;
            }
            if (t < 1f / 6f)
            {
                return p + (q - p) * 6 * t;
            }
            else if (t < 0.5f)
            {
                return q;
            }
            else if (t < 2f / 3f)
            {
                return p + (q - p) * (2f / 3f - t) * 6;
            }
            return p;
        }

        float q;
        if (l < 0.5)
        {
            q = l * (1 + s);
        }
        else
        {
            q = l + s - l * s;
        }
        float p = 2 * l - q;
        r = pqt(p, q, h + 1f / 3f);
        g = pqt(p, q, h);
        b = pqt(p, q, h - 1f / 3f);
    }
    return Pixel(cast(int)(r * 255f), cast(int)(g * 255f), cast(int)(b * 255f));
}

Hsl toHsl(Pixel p)
{
    Hsl h;
    float r = p.r / 255f;
    float g = p.g / 255f;
    float b = p.b / 255f;
    float mx = max(r, g, b);
    float mn = min(r, g, b);
    if (mx == mn)
    {
        h = Hsl(0, 0, mx);
    }
    else
    {
        float avg = (mx + mn) / 2f;
        float dif = mx - mn;
        h = Hsl(avg, avg, avg);
        if (h.l > 0.5)
        {
            h.s = dif / (2f - mx - mn);
        }
        else
        {
            h.s = dif / (mx + mn);
        }
        if (r == mx)
        {
            h.h = (g - b) / dif + (g < b ? 6f : 0);
        }
        else if (g == mx)
        {
            h.h = (b - r) / dif + 2;
        }
        else
        {
            h.h = (r - g) / dif + 4;
        }
        h.h /= 6f;
    }
    return h;
}

struct Point
{
    int x, y;
}

struct Hsl
{
    float h, s, l;
}
