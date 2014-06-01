package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;

class Enemy extends FlxSprite {
    public var moneyGain:Bool = true;
    public var maxHealth:Float = 1.0;

    /**
	 * Create a new enemy. Used in the menu and playstate.
	 *
	 * @param	X	The X position for the enemy.
	 * @param	Y	The Y position for the enemy.
	 */
    override public function new(X:Int, Y:Int) {
        super(X, Y, Reg.enemyImage);

        health = maxHealth;
    }

    /**
	 * Reset this enemy at X,Y and reset their health. Used for object pooling in the PlayState.
	 *
	 * @param	X	The X position for the enemy.
	 * @param	Y	The Y position for the enemy.
	 */
    public function init(X:Int, Y:Int) {
        reset(X, Y);

        if(Reg.PS != null) {
            health = Math.floor(Reg.PS.wave / 3) + 1;
        }

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
	 * Start this enemy on a path, as represented by an array of FlxPoints. Updates position to the first node
	 * and then uses FlxPath.start() to set this enemy on the path. Speed is determined by wave number, unless
	 * in the menu, in which case it's arbitrary.
	 *
	 * @param	Path	The path to follow.
	 */
    public function followPath(Path:Array<FlxPoint>):Void {
        if(Path == null) {
            throw("No valid path was passed to the enemy! Does the tilemap provide a valid path from start to finish?");
        }

        x = Path[0].x;
        y = Path[0].y;

        if(Reg.PS != null) {
            new FlxPath(this, Path, 20 + Reg.PS.wave, 0, true);
        }
        else {
            new FlxPath(this, Path, 50, 0, true);
        }
    }
}