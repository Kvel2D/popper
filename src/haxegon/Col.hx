package haxegon;

// From Arne's legendary 16 colour palette: http://androidarts.com/palette/16pal.htm

class Col {
    public static inline var BLACK:Int = 0x000000;
    public static inline var GREY:Int = 0x9D9D9D;
    public static inline var GRAY:Int = 0x9D9D9D;
    public static inline var WHITE:Int = 0xFFFFFF;
    public static inline var RED:Int = 0xBE2633;
    public static inline var PINK:Int = 0xE06F8B;
    public static inline var DARKBROWN:Int = 0x493C2B;
    public static inline var BROWN:Int = 0xA46422;
    public static inline var ORANGE:Int = 0xEB8931;
    public static inline var YELLOW:Int = 0xF7E26B;
    public static inline var DARKGREEN:Int = 0x2F484E;
    public static inline var GREEN:Int = 0x44891A;
    public static inline var LIGHTGREEN:Int = 0xA3CE27;
    public static inline var NIGHTBLUE:Int = 0x1B2632;
    public static inline var DARKBLUE:Int = 0x005784;
    public static inline var BLUE:Int = 0x31A2F2;
    public static inline var LIGHTBLUE:Int = 0xB2DCEF;
    public static inline var MAGENTA:Int = 0xFF00FF;

    public static var ALL = [BLACK, GRAY, WHITE, RED, PINK, DARKBROWN, BROWN, ORANGE,
    YELLOW, DARKGREEN, GREEN, LIGHTGREEN, NIGHTBLUE, DARKBLUE, BLUE, LIGHTBLUE, MAGENTA];

    public static var TRANSPARENT:Int = 0x000001;

    public static function r(color: Int) {
    	return color >> 16;
    }

    public static function g(color: Int) {
    	return (color & 0x00FF00) >> 8;
    }

    public static function b(color: Int) {
    	return color & 0x0000FF;
    }

    public static function rgb(r: Int, g: Int, b: Int): Int {
        return (r << 16) | (g << 8) | b;
    }

    private static var hslval = [0.0, 0.0, 0.0];
    public static function hsl(hue: Float, saturation: Float, lightness: Float): Int {
        var q: Float = if (lightness < 1 / 2) {
            lightness * (1 + saturation);
        } else {
            lightness + saturation - (lightness * saturation);
        }

        var p: Float = 2 * lightness - q;

        var hk: Float = ((hue % 360) / 360);

        hslval[0] = hk + 1 / 3;
        hslval[1] = hk;
        hslval[2] = hk - 1 / 3;
        for (n in 0 ... 3) {
            if (hslval[n] < 0) hslval[n] += 1;
            if (hslval[n] > 1) hslval[n] -= 1;
            hslval[n] = if (hslval[n] < 1 / 6) {
                p + ((q - p) * 6 * hslval[n]);
            } else if (hslval[n] < 1 / 2) {
                q;
            } else if (hslval[n] < 2 / 3) {
                p + ((q - p) * 6 * (2 / 3 - hslval[n]));
            } else {
                p;
            }
        }

        return rgb(Std.int(hslval[0] * 255), Std.int(hslval[1] * 255), Std.int(hslval[2] * 255));
    }
}