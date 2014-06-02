package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.group.FlxTypedGroup;

class Tower extends FlxSprite {

    public var range:Int = 40;     // 射程範囲
    public var fireRate:Float = 1; // 攻撃回数
    public var damage:Int = 1;     // 攻撃力


    public var range_LEVEL:Int = 1;    // 射程範囲レベル
    public var firerate_LEVEL:Int = 1; // 攻撃回数レベル
    public var damage_LEVEL:Int = 1;   // 威力レベル

    public var range_PRIZE:Int = BASE_PRIZE;    // 射程範囲の価格
    public var firerate_PRIZE:Int = BASE_PRIZE; // 攻撃回数の価格
    public var damage_PRIZE:Int = BASE_PRIZE;   // 威力の価格

    private var _shootInvertall:Int = 2; // 発射のインターバル
    private var _shootCounter:Int = 0;   // 発射までのカウンタ(1フレームにつき1上昇)
    private var _initialCost:Int = 0;    // 初期コスト。売却時に使用する
    private var _indicator:FlxSprite;

    private static var HELPER_POINT:FlxPoint = FlxPoint.get();
    private static var HELPER_POINT_2:FlxPoint = FlxPoint.get();

    private static inline var COST_INCREASE:Float = 1.5;
    private static inline var BASE_PRIZE:Int = 10;

    /**
     * 生成
     * @param x 座標(X)
     * @param y 座標(Y)
     */
    public function new(X:Float, Y:Float, Cost:Int) {
        super(X, Y, "images/tower.png");

        _indicator = new FlxSprite(getMidpoint().x - 1, getMidpoint().y - 1);
        _indicator.makeGraphic(2, 2);
        Reg.PS.towerIndicators.add(_indicator);

        _initialCost = Cost;
    }

    /**
     * 更新
     */
    override public function update():Void {
        if(getNearestEnemy() == null) {
            _indicator.visible = false;
        }
        else {
            _indicator.visible = true;
            // 発射可能に近づくほどインジケーターをアルファ値が大きくなる
            _indicator.alpha = _shootCounter / (_shootInvertall * FlxG.updateFramerate);

            _shootCounter += Std.int(FlxG.timeScale);

            if(_shootCounter > (_shootInvertall * FlxG.updateFramerate) * fireRate) {
                shoot();
            }
        }

        super.update();
    }

    /**
     * 売却価格の取得
     */
    public var value(get, null):Int;

    private function get_value():Int {
        var val:Float = _initialCost;

        val += range_PRIZE - BASE_PRIZE;
        val += firerate_PRIZE - BASE_PRIZE;
        val += damage_PRIZE - BASE_PRIZE;
        val = Math.round(val / 2);

        return Std.int(val);
    }

    /**
     * 弾を撃つ
     */
    private function shoot():Void {
        var target:Enemy = getNearestEnemy();

        if(target == null) {
            return;
        }

        var bullet:Bullet = Reg.PS.bulletGroup.recycle(Bullet);
        getMidpoint(HELPER_POINT);
        bullet.init(HELPER_POINT.x, HELPER_POINT.y, target, damage);

        FlxG.sound.play("shoot");

        _shootCounter = 0;
    }

    /**
     * 一番近い敵を探す (正確には範囲内にいるインデックスの小さい敵)
     */
    private function getNearestEnemy():Enemy {
        var firstEnemy:Enemy = null;
        var enemies:FlxTypedGroup<Enemy> = Reg.PS.enemyGroup;

        for(enemy in enemies) {
            if(enemy != null && enemy.alive) {
                HELPER_POINT.set(x, y);
                HELPER_POINT_2.set(enemy.x, enemy.y);
                var distance:Float = FlxMath.getDistance(HELPER_POINT, HELPER_POINT_2);

                if(distance <= range) {
                    firstEnemy = enemy;
                    break;
                }
            }
        }

        return firstEnemy;
    }

    /**
     * 射程範囲のアップグレード
     */
    public function upgradeRange():Void {
        range += 10;
        range_LEVEL++;
        range_PRIZE = Std.int(range_PRIZE * COST_INCREASE);
    }

    /**
     * 威力のアップグレード
     */
    public function upgradeDamage():Void {
        damage++;
        damage_LEVEL++;
        damage_PRIZE = Std.int(damage_PRIZE * COST_INCREASE);
    }

     /**
      * 発射間隔のアップグレード
      * 発射間隔：rate x 0.9だけ短くなる
      * 価格：prize x 1.5上昇する
      */
    public function upgradeFirerate():Void {
        fireRate *= 0.9;
        firerate_LEVEL++;
        firerate_PRIZE = Std.int(firerate_PRIZE * COST_INCREASE);
    }
}
