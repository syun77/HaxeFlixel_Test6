# ゲーム仕様

## タワーの価格
初期状態は$8。購入ごとに1.3倍上昇する。なお端数は1回の計算ごとに切り捨てる

| 購入数  | 価格 |
| ------------- | ------------- |
| 1  | $8  |
| 2  | $10  |
| 3  | $13  |
| 4  | $16  |
| 5  | $20  |
| 6  | $26  |
| 7  | $33  |
| 8  | $42  |
| 9  | $54  |
| 10  | $70  |
| i1  | $91  |
| i2  | $118  |

## タワーアップグレードの価格
初期状態は$10。購入ごとに1.5倍上昇する。なお端数は1回の計算ごとに切り捨てる

| レベル  | 価格 |
| ------------- | ------------- |
| 1  | $10  |
| 2  | $15  |
| 3  | $22  |
| 4  | $33  |
| 5  | $49  |
| 6  | $73  |
| 7  | $109  |
| 8  | $163  |

## 射程範囲
初期状態は40px。レベル上昇ごとに+10pxだけ広がる

## 攻撃威力
初期状態は1。レベル上昇ごとに+1

## 発射間隔
初期状態では2秒かかる。レベル上昇ごとに0.9ずつ低減していく
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

## 敵のパラメータ
* 出現数 : Wave数 + 5 
* 体力 : Wave数/3 + 1 (端数は切り捨て)
* 移動速度 : Wave数 + 20

| Wave数 | 出現数 | 体力 | 移動速度 |
| ------------- | ------------- | ------------ |
| 1 | 6 | 1 | 20 |
| 2 | 7 | 1 | 21 |
| 3 | 8 | 2 | 22 |
| 4 | 9 | 2 | 23 |
| 5 | 10 | 2 | 24 |
| 6 | 11 | 3 | 25 |
| 7 | 12 | 3 | 26 |
| 8 | 13 | 3 | 27 |
| 9 | 14 | 4 | 28 |
| 10 | 15 | 4 | 29 |

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

## Tweenアニメ
Wave開始やゲームオーバー時にはTweenアニメを使用している。
初期座標を x=-200 に設定して、x=0 へ向かって減速しながら進む(FlxEase.expoOut)。

```hx
    /**
     * Wave開始テストやゲームオーバーのテキストを表示します
     * @param End trueの場合ゲームオーバーテキストを表示する
     */
    private function announceWave(End:Bool = false):Void {

        // 位置を x=-200 に設定
        _centerText.x = -200;
        _centerText.text = "Wave " + wave;

        if(End) {
            _centerText.text = "Game Over! :(";
        }

        // アニメーション実行
        // obj : 対象となるFlxObject
        // values : 操作するFlxObjectのパラメータ
        // duration : アニメーション時間 (秒)
        // options : オプション
        //             - type : 種別
        //             - complete : 完了時のコールバック関数
        //             - ease : イージング種別
        //             - startDelay : 開始ディレイ時間
        //             - loopDelay : ループディレイ時間
        // ここでは x=-200 から x=0 に向かって減速しながら移動する
        FlxTween.tween(_centerText, { x: 0 }, 2, { ease: FlxEase.expoOut, complete: hideText });

        _waveText.text = "Wave: " + wave;
        _waveText.size = 16;
        _waveText.visible = true;
    }
```

アニメ完了後は、hideText()を呼び出すようにしている。
画面外に加速しながら退出するアニメーション(FlxEase.expoIn)を呼び出している。

```hx
    /**
     * アナウンステキストのフェードアウト
     */
    private function hideText(Tween:FlxTween):Void {
        FlxTween.tween(_centerText, { x: FlxG.width }, 2, { ease: FlxEase.expoIn });
    }
```

