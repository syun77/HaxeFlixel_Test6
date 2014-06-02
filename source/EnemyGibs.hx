package ;

import flash.display.BlendMode;
import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxRandom;

/**
 * 敵消滅エフェクトのエミッタ
 */
class EnemyGibs extends FlxEmitter {
    private static inline var SPEED:Int = 10;
    private static inline var SIZE:Int = 10;

    /**
     * 生成
     */
    public function new() {

        // 大きさを設定
        super(0, 0, SIZE);

        // 速度を設定
        setXSpeed(-SPEED, SPEED);
        setYSpeed(-SPEED, SPEED);

        #if !(cpp || neko || js)
        // 減算合成する
		blend = BlendMode.INVERT;
        #end

        // パーティクルを登録
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

        // エミッタグループに登録
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
        // Quantity : 10 -> 出現させる量。ここでは全部出している
        // LifeSpanRange : 1 -> 生存時間の範囲
        start(true, 1, 0, SIZE, 1);
    }
}