package;

import kha.System;
import kha.Framebuffer;
import kha.Assets;
import kha.Color;

class Loader {
    @:allow(Main)
    static var onDone:Void->Void = null;

    @:allow(Main)
    static function load():Void {
        System.notifyOnRender(render);
        Assets.loadEverything(function() {
            System.removeRenderListener(render);
            onDone();
        });
    }

    static var bg:Color = Color.Black;
    static var barbg:Color = Color.fromFloats(0.25, 0.25, 0.25, 1);
    static var barfg:Color = Color.White;
    static var barw:Float = 256;
    static var barh:Float = 4;

	static function render(fb:Framebuffer):Void {
		var g = fb.g2;
		g.begin(true, bg);

        var sw:Float = System.windowWidth();
        var sh:Float = System.windowHeight();
        g.color = barbg;
        g.fillRect((sw - barw) / 2, (sh - barh) / 2, barw, barh);
        g.color = barfg;
        g.fillRect((sw - barw) / 2, (sh - barh) / 2, barw * Assets.progress, barh);

		g.end();
	}
}
