package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;

class Enemy extends FlxSprite {
    public var moneyGain:Bool = true;
    public var maxHealth:Float = 1.0; // 最大HP

    /**
     * 生成
     * @param x 座標(X)
     * @param y 座標(Y)
     */
    override public function new(X:Int, Y:Int) {
        super(X, Y, Reg.enemyImage);

        // 体力を設定
        health = maxHealth;
    }

    /**
     * 初期化
     * @param x 座標(X)
     * @param y 座標(Y)
     */
    public function init(X:Int, Y:Int) {
        reset(X, Y);

        if(Reg.PS != null) {
            // 体力を設定 (Wave数/3) + 1
            health = Math.floor(Reg.PS.wave / 3) + 1;
        }

        // 最大HPを設定
        maxHealth = health;
    }

    /**
	 * The alpha of the enmy is dependent on health.
	 */
    override public function update():Void {
        alpha = health / maxHealth;

        super.update();
    }

    /**
	 * ダメージ処理
	 * @param Damage ダメージ量
	 */
    override public function hurt(Damage:Float):Void {
        health -= Damage;

        if(health <= 0) {
            // 体力がなくなったので爆発
            explode(true);
        }
    }

    /**
	 * 敵消滅処理
	 * @param GainMoney お金が獲得できるかどうか
	 */
    public function explode(GainMoney:Bool):Void {
        // 敵消滅SEを再生
        FlxG.sound.play("enemykill");

        // 消滅エフェクト再生
        var emitter:EnemyGibs = Reg.PS.emitterGroup.recycle(EnemyGibs);
        emitter.explode(x, y);

        // 敵の総数を減らす
        Reg.PS.enemiesToKill--;

        if(Reg.PS.enemiesToKill <= 0) {
            // 敵の残数が0なら次のWaveへ進む
            Reg.PS.killedWave();
        }

        if(GainMoney) {
            // お金獲得
            var money:Int = (Reg.PS.wave < 5) ? 2 : 1;

            Reg.PS.money += money;
        }

        // 敵消滅
        super.kill();
    }

    /**
     * 移動パスの生成
     * @param Path 移動パスの配列
     */
    public function followPath(Path:Array<FlxPoint>):Void {
        if(Path == null) {
            throw("No valid path was passed to the enemy! Does the tilemap provide a valid path from start to finish?");
        }

        // 初期位置はパスの先頭の座標
        x = Path[0].x;
        y = Path[0].y;

        if(Reg.PS != null) {
            // パスを生成する
            // this:  FlxObject       パスで制御するインスタンス
            // Path:  Array<FlxPoint> 移動パスの配列
            // speed: Float           移動速度
            // mode:  Int             動作モード(デフォルト:FORWARD[前進])
            new FlxPath(this, Path, 20 + Reg.PS.wave, 0, true);
        }
        else {
            new FlxPath(this, Path, 50, 0, true);
        }
    }
}