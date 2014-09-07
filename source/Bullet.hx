package;

import flash.display.BlendMode;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxVelocity;

/**
 * 弾
 **/
class Bullet extends FlxSprite {
    /**
	 * The amount of damage this bullet will do to an enemy. Set only via init().
	 */
    public var damage(default, null):Int;

    /**
	 * This bullet's targeted enemy. Set via init(), and determines direction of motion.
	 */
    private var _target:Enemy;

    /**
	 * Create a new Bullet object. Generally this would be used by the game to create a pool of bullets that can be recycled later on, as needed.
	 */
    public function new() {
        super();
        makeGraphic(3, 3);

        #if !(cpp || neko || js)
		blend = BlendMode.INVERT;
        #end
    }

    /**
     * 弾を指定の座標・ターゲット・ダメージ量で初期化します。通常Towerから発射されます
     * @param X 座標(X)
     * @param Y 座標(Y)
     * @param Target ターゲット（エネミー）
     * @param Damage 弾のダメージ量。この値はTowerをアップグレードしたレベルによって決まります
     **/
    public function init(X:Float, Y:Float, Target:Enemy, Damage:Int):Void {
        reset(X, Y);
        _target = Target;
        damage = Damage;
    }

    /**
     * 更新
     **/
    override public function update():Void {

        // ターゲットを外したり画面外に出たら消す
        if(!isOnScreen(FlxG.camera)) {
            // 画面外に出たら消す
            kill();
        }

        // init()で割り当てたターゲットに向かって移動させる
        if(_target.alive) {
            // 一度発射されたらどこまでも飛んで行く
            FlxVelocity.moveTowardsObject(this, _target, 200);
        }

        // 更新
        super.update();
    }
}