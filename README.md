HaxeFlixel_Test6
================

# ゲーム仕様
## 発射間隔
    if(_shootCounter > (_shootInvertall * FlxG.updateFramerate) * fireRate) {
      // 発射カウンタが (インターバル * フレームレート) * 攻撃回数レベル
      // より大きければ発射できる
      // 初期状態 = 2 * 60 * 1 = 2秒かかる 
      shoot();
    }

# 技術情報


