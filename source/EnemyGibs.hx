package ;

import flash.display.BlendMode;
import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxRandom;

/**
 * 敵消滅エフェクト
 */
class EnemyGibs extends FlxEmitter {
    private static inline var SPEED:Int = 10;
    private static inline var SIZE:Int = 10;

    /**
	 * Creates a FlxEmitter with pre-defined particle size, speed, color, inversion, and so forth.
	 */
    public function new() {
        super(0, 0, SIZE);

        setXSpeed(-SPEED, SPEED);
        setYSpeed(-SPEED, SPEED);

        #if !(cpp || neko || js)
		blend = BlendMode.INVERT;
        #end

        for(i in 0...SIZE) {
            var p:FlxParticle = new FlxParticle();

            #if !(cpp || neko || js)
			p.makeGraphic(2, 2, FlxColor.BLACK);
            #else
			if (FlxRandom.chanceRoll())
			{
				p.makeGraphic(2, 2, FlxColor.BLACK);
			}
			else
			{
				p.makeGraphic(2, 2, FlxColor.WHITE);
			}
			#end
            add(p);
        }

        Reg.PS.emitterGroup.add(this);
    }

    /**
     * 敵消滅エフェクト
     * @param x 座標(X)
     * @param y 座標(Y)
     */
    public function explode(X:Float, Y:Float):Void {
        x = X;
        y = Y;

        // Explode : true -> 一斉にすべて出現する
        // Lifespan : 1 -> 生存時間は1秒
        // Frequecy : 0 -> Explodeをfalseにした場合の出現間隔。ここでは無視される
        // Quantity :
        start(true, 1, 0, SIZE, 1);
    }
}