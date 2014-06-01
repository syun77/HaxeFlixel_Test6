# ゲーム仕様
## 発射間隔
### 計算式
計算式は、
`カウンタ > インターバル x フレームレート x レベル`

```hx
if(_shootCounter > (_shootInvertall * FlxG.updateFramerate) * fireRate) {
  // 発射カウンタが (インターバル x フレームレート) x 攻撃回数レベル
  // より大きければ発射できる
  // 初期状態 = 2 x 60 x 1 = 2秒かかる 
  shoot();
}
```

### レベルに対応する必要な時間

```hx
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
```

| 攻撃回数レベル  | 発射可能になる時間 |
| ------------- | ------------- |
| 1  | 2秒  |
| 2  | 1.8秒  |
| 3  | 1.62秒  |
| 4  | 1.458秒  |
| 5  | 1.3122秒  |
| 6  | 1.18098秒  |

# 技術情報
## 経路探索
パスはFlxTilemap.findPath()で作成する

```hx
// 敵をパスで動かす(見つからなかった場合はnull)
var pList:Array<FlxPoint> = _map.findPath(
    FlxPoint.get(_enemySpawnX, _enemySpawnY), // 開始座標
    FlxPoint.get(_goalX + 5, _goalY + 5),     // 終了座標
    true,                                     // 重複を削除(デフォルト:true)
    false,                                    // 障害物を斜め移動することを許可する(デフォルト:false)
    true                                      // 斜め移動するための追加タイルが必要か(デフォルト:true)
);
enemy.followPath(pList);
```

実際の移動はFlxPathを使って行う

```hx
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
```

