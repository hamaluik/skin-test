import kha.System;
import kha.Scheduler;

class Main {
    public static function main() {
        Loader.onDone = function():Void {
            Game.initialize();
            System.notifyOnRender(Game.render);
            Scheduler.addTimeTask(Game.update, 0, 1/60);
        };
        System.init({ title: "Skin Test", width: 1280, height: 720}, Loader.load);
    }
}
