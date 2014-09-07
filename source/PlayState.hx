package;

import flash.display.Sprite;
import openfl.Assets;
import flash.display.BlendMode;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;

enum MenuType {
    General;
    Upgrade;
    Sell;
    ConfirmSell;
}

/**
 * メインゲーム
 **/
class PlayState extends FlxState {
    /**
	 * Helper Sprite object to draw tower's range graphic
	 */
    private static var RANGE_SPRITE:Sprite = null;

    #if debug
	private static inline var MONEY_CHEAT:Bool = true;
	#end

    // Public variables
    public var enemiesToKill:Int = 0;
    public var enemiesToSpawn:Int = 0;
    public var towerPrice:Int = 8; // タワーの価格
    public var wave:Int = 0; // Wave数

    // Public groups
    public var bulletGroup:FlxTypedGroup<Bullet>; // ショットグループ
    public var emitterGroup:FlxTypedGroup<EnemyGibs>; // エフェクトグループ
    public var enemyGroup:FlxTypedGroup<Enemy>; // 敵グループ
    public var towerIndicators:FlxTypedGroup<FlxSprite>; // タワーグループ

    // Groups
    private var _guiGroup:FlxGroup;
    private var _lifeGroup:FlxGroup;
    private var _topGui:FlxGroup;
    private var _towerGroup:FlxTypedGroup<Tower>;
    private var _upgradeMenu:FlxGroup;
    private var _sellMenu:FlxGroup;
    private var _sellConfirm:FlxGroup;

    // Sprites
    private var _buildHelper:FlxSprite;
    private var _goal:FlxSprite; // ゴール
    private var _towerRange:FlxSprite;

    // Text
    private var _centerText:FlxText; // Wave開始やゲームオーバーを伝えるテキスト
    private var _enemyText:FlxText; // 敵情報テキスト
    private var _moneyText:FlxText;
    private var _tutText:FlxText;
    private var _waveText:FlxText;
    private var _areYouSure:FlxText;

    // Buttons
    private var _damageButton:Button;
    private var _firerateButton:Button;
    private var _nextWaveButton:Button;
    private var _rangeButton:Button;
    private var _speedButton:Button; // ゲームスピード変更ボタン
    private var _towerButton:Button;
    private var _sellButton:Button;

    // Other objects
    private var _map:FlxTilemap;
    private var _towerSelected:Tower; // 選択しているタワー

    // Private variables

    private var _buildingMode:Bool = false; // タワー設置モードかどうか
    private var _gameOver:Bool = false;
    private var _lives:Int = 9;
    private var _money:Int = 50;
    private var _spawnCounter:Int = 0;
    private var _spawnInterval:Int = 1;
    private var _speed:Int = 1;
    private var _waveCounter:Int = 0;

    private var _enemySpawnX:Int = 25; // 敵出現座標(X)
    private var _enemySpawnY:Int = -6; // 敵出現座標(Y)
    private var _goalX:Int = 245; // ゴール座標(X)
    private var _goalY:Int = 43; // ゴール座標(Y)

    public function new() {
        super();
    }

    /**
	 * 生成
	 */
    override public function create():Void {
        // 自身を登録
        Reg.PS = this;

        // BGM再生開始
        FlxG.sound.playMusic("td2");

        FlxG.timeScale = 1;

        // 地形読み込み
        _map = new FlxTilemap();
        _map.loadMap(Assets.getText("tilemaps/play_tilemap.csv"), Reg.tileImage);

        // 各種グループ生成
        bulletGroup = new FlxTypedGroup<Bullet>();
        emitterGroup = new FlxTypedGroup<EnemyGibs>();
        enemyGroup = new FlxTypedGroup<Enemy>();
        _towerGroup = new FlxTypedGroup<Tower>();
        towerIndicators = new FlxTypedGroup<FlxSprite>();

        // GUIの設定
        var guiUnderlay:FlxSprite = new FlxSprite(0, FlxG.height - 16);
        guiUnderlay.makeGraphic(FlxG.width, 16, FlxColor.WHITE);

        _guiGroup = new FlxGroup();

        var height:Int = FlxG.height - 18;
        // タワー購入ボタン
        _towerButton = new Button(2, height, "Buy [T]ower ($" + towerPrice + ")", buildTowerCallback.bind(false), 120);
        _nextWaveButton = new Button(100, height, "[N]ext Wave", nextWaveCallback.bind(false), 143);
        // ゲームスピード変更ボタン
        _speedButton = new Button(FlxG.width - 20, height, "x1", speedButtonCallback.bind(false), 21);
        _sellButton = new Button(220, height, "[S]ell Mode", sellButtonCallback.bind(true));
        _sellButton.visible = false;

        _tutText = new FlxText(0, height - 10, FlxG.width, "Click on a Tower to Upgrade it!");
        _tutText.alignment = "center";
        _tutText.visible = false;

        _guiGroup.add(_towerButton);
        _guiGroup.add(_nextWaveButton);
        _guiGroup.add(_speedButton);
        _guiGroup.add(_sellButton);
        _guiGroup.add(_tutText);

        // メニューを設定
        _upgradeMenu = new FlxGroup();

        _rangeButton = new Button(14, height, "Range (##): $##", upgradeRangeCallback);
        _damageButton = new Button(100, height, "Damage (##): $##", upgradeDamageCallback);
        _firerateButton = new Button(200, height, "Firerate (##): $##", upgradeFirerateCallback);

        _upgradeMenu.add(new Button(2, height, "<", toggleMenus.bind(General), 10));
        _upgradeMenu.add(_rangeButton);
        _upgradeMenu.add(_damageButton);
        _upgradeMenu.add(_firerateButton);

        _upgradeMenu.visible = false;

        // 売却モードのメニューを設定
        _sellMenu = new FlxGroup();

        var sellMessage:FlxText = new FlxText(0, height + 3, FlxG.width, "Click on a tower to sell it");
        sellMessage.color = FlxColor.BLACK;
        sellMessage.alignment = "center";

        _sellMenu.add(sellMessage);
        _sellMenu.add(new Button(2, height, "<", sellMenuCancel.bind(false), 10));

        _sellMenu.visible = false;

        // 売却確認メニューを設定
        _sellConfirm = new FlxGroup();

        _areYouSure = new FlxText(20, height + 3, 200, "Tower value $###, really sell?");
        _areYouSure.color = FlxColor.BLACK;

        _sellConfirm.add(new Button(2, height, "<", sellMenuCancel.bind(false), 10));
        _sellConfirm.add(_areYouSure);
        _sellConfirm.add(new Button(220, height, "[Y]es", sellConfirmCallback.bind(true)));
        _sellConfirm.add(new Button(280, height, "[N]o", sellConfirmCallback.bind(false)));

        _sellConfirm.visible = false;

        // GUIを設定
        // ルートとなるGUI
        _topGui = new FlxGroup();

        // 所持金テキスト
        _moneyText = new FlxText(0, 2, FlxG.width - 4, "$: " + money);
        _moneyText.alignment = "right";

        // 敵情報テキスト作成
        _enemyText = new FlxText(80, 2, FlxG.width, "Wave");
        _enemyText.visible = false;

        // Wave数表示テキスト作成
        _waveText = new FlxText(180, 2, FlxG.width, "Wave");
        _waveText.visible = false;

        _topGui.add(_moneyText);
        _topGui.add(_enemyText);
        _topGui.add(_waveText);

        // ゴールを作成
        _goal = new FlxSprite(_goalX, _goalY, "images/goal.png");

        // 残りライフ数表示
        _lifeGroup = new FlxGroup();

        // 初期ライフは 3x3=9
        for(xPos in 0...3) {
            for(yPos in 0...3) {
                var life:FlxSprite = new FlxSprite(_goal.x + 5 + 4 * xPos, _goal.y + 5 + 4 * yPos);
                life.makeGraphic(2, 2, FlxColor.WHITE);
                _lifeGroup.add(life);
            }
        }

        // Wave開始やゲームオーバーを伝えるテキストの生成
        _centerText = new FlxText( -200, FlxG.height / 2 - 20, FlxG.width, "", 16);
        _centerText.alignment = "center";
        _centerText.borderStyle = FlxText.BORDER_SHADOW;

        #if !(cpp || neko || js)
		_centerText.blend = BlendMode.INVERT; // 反転合成で描画する
        #end

        _buildHelper = new FlxSprite(0, 0, "images/checker.png");
        _buildHelper.visible = false;

        _towerRange = new FlxSprite(0, 0);
        _towerRange.visible = false;

        // Add everything to the state

        add(_map);
        add(bulletGroup);
        add(emitterGroup);
        add(enemyGroup);
        add(_towerRange);
        add(_towerGroup);
        add(towerIndicators);
        add(_goal);
        add(_lifeGroup);
        add(_buildHelper);
        add(guiUnderlay);
        add(_guiGroup);
        add(_upgradeMenu);
        add(_sellMenu);
        add(_sellConfirm);
        add(_topGui);
        add(_centerText);

        // Call this to set up for first wave

        killedWave();

        // This is a good place to put watch statements during development.
        #if debug
		//FlxG.watch.add( _sellMenu, "visible" );
		#end
    }

    /**
	 * Wave終了
	 */
    public function killedWave():Void {
        if(wave != 0) {
            FlxG.sound.play("wavedefeated");
        }

        // 3秒待つ
        _waveCounter = 3 * FlxG.updateFramerate;

        // 次へ進むボタンを表示
        _nextWaveButton.visible = true;

        // 敵残数テキストを非表示
        _enemyText.visible = false;
    }

    /**
	 * 更新
	 */
    override public function update():Void {
        // Update enemies left indicator

        // 敵の残数テキスト更新
        _enemyText.text = "Enemies left: " + enemiesToKill;

        // テキストアニメーション。サイズが8以上なら1つ減らす
        if(_moneyText.size > 8) {
            _moneyText.size--;
        }

        if(_enemyText.size > 8) {
            _enemyText.size--;
        }

        if(_waveText.size > 8) {
            _waveText.size--;
        }

        // キーボード入力判定
        #if !mobile
		if(FlxG.keys.justReleased.T) buildTowerCallback(true);
        if(FlxG.keys.justReleased.SPACE) speedButtonCallback(true);
        if(FlxG.keys.justReleased.S) sellButtonCallback(true);
        if(FlxG.keys.justReleased.Y) sellConfirmCallback(true);
        if(FlxG.keys.justReleased.ESCAPE) {
            // ESCAPEでタイトル画面に戻る
            FlxG.sound.destroy(true);
            FlxG.switchState(new MenuState());
        }
        if(FlxG.keys.justReleased.N) {
            if(_sellConfirm.visible) {
                sellConfirmCallback(false);
            }
            else {
                nextWaveCallback(true);
            }
        }
        if(FlxG.keys.justReleased.ESCAPE) toggleMenus(General);
        if(FlxG.keys.justReleased.ONE) upgradeRangeCallback();
        if(FlxG.keys.justReleased.TWO) upgradeDamageCallback();
        if(FlxG.keys.justReleased.THREE) upgradeFirerateCallback();
        #end

        // If needed, updates the grid highlight square buildHelper and the range indicator
        #if !mobile
		if(_buildingMode) {
            // マウス座標を取得してグリッドカーソルを更新
            _buildHelper.x = FlxG.mouse.x - (FlxG.mouse.x % 8);
            _buildHelper.y = FlxG.mouse.y - (FlxG.mouse.y % 8);
            updateRangeSprite(_buildHelper.getMidpoint(), 40);
        }
        #end

        // Controls mouse clicks, which either build a tower or offer the option to upgrade a tower.

        if(FlxG.mouse.justReleased) {
            // マウスを離した
            if(_buildingMode) {
                // タワー設置モードならばタワー建設
                buildTower();
            }
            else {
                var selectedTower:Bool = false;

                #if !mobile
				// If the user clicked on a tower, they get the upgrade menu, or the sell menu
                for(tower in _towerGroup) {
                    if(FlxMath.pointInCoordinates(Std.int(FlxG.mouse.x), Std.int(FlxG.mouse.y), Std.int(tower.x), Std.int(tower.y), Std.int(tower.width), Std.int(tower.height))) {
                        // クリック先にタワーが存在
                        // タワーを選択状態にする
                        _towerSelected = tower;

                        if(_sellMenu.visible || _sellConfirm.visible) {
                            sellConfirmCheck();

                        }
                        else {
                            toggleMenus(Upgrade);
                        }

                        selectedTower = true;

                        break; // We've found the selected tower, can stop cycling through them
                    }
                }

                // If the user didn't click on any towers, we go back to the general menu

                if(!selectedTower && FlxG.mouse.y < FlxG.height - 20) {
                    toggleMenus(General);
                }
                #else
				// If the user tapped NEAR a tower, they get the upgrade menu.
				var nearestTower:Tower = getNearestTower(FlxG.mouse.x, FlxG.mouse.y, 20);

				if (nearestTower != null)
				{
					_towerSelected = nearestTower;

					if (_sellMenu.visible || _sellConfirm.visible)
					{
						sellConfirmCheck();

					}
					else
					{
						toggleMenus(Upgrade);
					}

					selectedTower = true;
				}

				// If the user didn't click near any towers, we go back to the general menu

				if (!selectedTower && (FlxG.mouse.y < FlxG.height - 20))
				{
					toggleMenus(General);
				}
				#end
            }
        }

        // 敵がゴールに到達したかどうか
        FlxG.overlap(enemyGroup, _goal, hitGoal);

        // ショットが敵にあたったかどうか
        FlxG.overlap(bulletGroup, enemyGroup, hitEnemy);

        // Controls wave spawning, enemy spawning,

        if(enemiesToKill == 0 && _towerGroup.length > 0) {
            _waveCounter -= Std.int(FlxG.timeScale);
            _nextWaveButton.text = "[N]ext Wave in " + Math.ceil(_waveCounter / FlxG.updateFramerate);

            if(_waveCounter <= 0) {
                spawnWave();
            }
        }
        else {
            _spawnCounter += Std.int(FlxG.timeScale);

            if(_spawnCounter > _spawnInterval * FlxG.updateFramerate && enemiesToSpawn > 0) {
                spawnEnemy();
            }
        }

        super.update();
    } // End update

    #if mobile
	/**
	 * Used to get the nearest tower within a particular search radius. Makes selecting towers easier for touch screens.
	 *
	 * @param	X				The X position of the screen touch.
	 * @param	Y				The Y position of the screen touch.
	 * @param	SearchRadius	How far from the touch point to search.
	 * @return	The nearest tower, as a Tower object.
	 */
	private function getNearestTower(X:Float, Y:Float, SearchRadius:Float):Tower
	{
		var minDistance:Float = SearchRadius;
		var closestTower:Tower = null;
		var searchPoint:FlxPoint = FlxPoint.get(X, Y);

		for (tower in _towerGroup)
		{
			var dist:Float = FlxMath.getDistance(searchPoint, tower.getMidpoint());

			if (dist < minDistance) {
				closestTower = tower;
				minDistance = dist;
			}
		}

		return closestTower;
	}
	#end

    /**
	  * 敵がゴールに到達
	  * @param enemy 敵
	  * @param goal  ゴール
	  */
    private function hitGoal(enemy:Dynamic, goal:Dynamic):Void {
        // ライフを減らす
        _lives--;

        // 敵消滅
        enemy.explode(false);

        if(_lives >= 0) {
            // まだライフに残りがある
            // ライフゲージを減らす
            _lifeGroup.members[_lives].kill();
        }

        if(_lives == 0) {
            // ゲームオーバー
            loseGame();
        }

        // やられSE再生
        FlxG.sound.play("hurt");
    }

    /**
	  * ショットが敵に当たった
	  * @param bullet タワーの弾
	  * @param enemy  敵
	  */
    private function hitEnemy(bullet:Dynamic, enemy:Dynamic):Void {
        // 敵にダメージ
        enemy.hurt(bullet.damage);
        bullet.kill();

        FlxG.sound.play("enemyhit");
    }

    /**
	 * Controls the displayed menu.
	 *
	 * @param	Menu	The desired menu; one of the enum constructors above this class.
	 */
    private function toggleMenus(Menu:MenuType):Void {
        _sellConfirm.visible = false;
        _sellMenu.visible = false;
        _upgradeMenu.visible = false;
        _guiGroup.visible = false;
        _towerRange.visible = false;

        switch (Menu)
        {
            case General:
                _towerSelected = null;
                _guiGroup.visible = true;
                _buildingMode = false;
                _buildHelper.visible = false;
            case Upgrade:
                updateUpgradeLabels();
                _upgradeMenu.visible = true;
            case Sell:
                _sellMenu.visible = true;
            case ConfirmSell:
                _sellConfirm.visible = true;
        }

        playSelectSound();
    }

    /**
     * タワー購入ボタンを押した
     */
    private function buildTowerCallback(Skip:Bool = false):Void {
        if(towerPrice > money) {
            return;
        }

        // 建設モード切り替え
        _buildingMode = !_buildingMode;
        #if !mobile
		_towerRange.visible = !_towerRange.visible;
        _buildHelper.visible = _buildingMode;
        #end

        playSelectSound();
    }

    /**
     * ゲームスピード変更ボタンを押した
     */
    private function speedButtonCallback(Skip:Bool = false):Void {
        if(!_guiGroup.visible && !Skip) {
            // 非表示かつスキップが有効なら、反応しない
            return;
        }

        // 1〜3の範囲にする
        if(_speed < 3) {
            _speed += 1;
        }
        else {
            _speed = 1;
        }

        // ゲームスピードを変更
        FlxG.timeScale = _speed;

        // テキスト更新
        _speedButton.text = "x" + _speed;

        // 選択SEを再生
        playSelectSound();
    }

    /**
	 * A function that is called when the user wants to sell a tower.
	 */
    private function sellButtonCallback(Skip:Bool = false):Void {
        if(!_guiGroup.visible || _towerGroup.length == 0) {
            return;
        }

        toggleMenus(Sell);

        if(_buildingMode) {
            _buildingMode = false;
            _towerRange.visible = false;
        }

        playSelectSound();
    }

    private function sellConfirmCheck():Void {
        _areYouSure.text = "Tower value $" + _towerSelected.value + ", really sell?";

        toggleMenus(ConfirmSell);

        updateRangeSprite(_towerSelected.getMidpoint(), _towerSelected.range);
    }

    private function sellConfirmCallback(Sure:Bool):Void {
        if(!_sellConfirm.visible) {
            return;
        }

        _towerRange.visible = false;

        if(Sure) {
            _towerGroup.remove(_towerSelected, true);
            _towerSelected.visible = false;

            // Remove the indicator for this tower as well
            for(indicator in towerIndicators) {
                if(indicator.x == _towerSelected.getMidpoint().x - 1 && indicator.y == _towerSelected.getMidpoint().y - 1) {
                    towerIndicators.remove(indicator, true);
                    indicator.visible = false;
                    indicator = null;
                }
            }

            // If there are no towers, having the tutorial text and sell button is a bit superfluous
            if(_towerGroup.countLiving() == -1 && _towerGroup.countDead() == -1) {
                _sellButton.visible = false;

                if(_tutText.visible) {
                    _tutText.visible = false;
                }
            }

            // Give the player their money back
            money += _towerSelected.value;

            // Revert the next tower price
            towerPrice = Math.ceil(towerPrice / 1.3);

            // Null out the removed tower
            _towerSelected = null;

            // Go back to the general menu
            toggleMenus(General);
        }
        else {
            toggleMenus(General);
        }
    }

    private function sellMenuCancel(Skip:Bool = false):Void {
        toggleMenus(General);
    }

    /**
	 * A function that is called when the user selects to call the next wave.
	 */
    private function nextWaveCallback(Skip:Bool = false):Void {
        if(!_guiGroup.visible && !Skip) {
            return;
        }

        if(enemiesToKill > 0) {
            return;
        }

        spawnWave();
        playSelectSound();
    }

    /**
	 * A function that is called when the user elects to restart, which is only possible after losing.
	 */
    private function resetCallback(Skip:Bool = false):Void {
        if(!_guiGroup.visible && !Skip) {
            return;
        }

        FlxG.resetState();
        playSelectSound();
    }

    /**
     * タワーを建てる
     */
    private function buildTower():Void {
        // Can't place towers on GUI

        if(FlxG.mouse.y > FlxG.height - 16) {
            // GUIエリアなので置けない
            return;
        }

        if(money < towerPrice) {
            // お金が足りない
            // 失敗SE再生
            FlxG.sound.play("deny");

            toggleMenus(General);
            return;
        }

        // 座標をグリッドに合わせる
        var xPos:Float = FlxG.mouse.x - (FlxG.mouse.x % 8);
        var yPos:Float = FlxG.mouse.y - (FlxG.mouse.y % 8);

        // Can't place towers on other towers

        for(tower in _towerGroup) {
            if(tower.x == xPos && tower.y == yPos) {
                // すでにタワーがあるので配置できない
                // 失敗SE再生
                FlxG.sound.play("deny");

                // 一般メニューに戻す
                toggleMenus(General);
                return;
            }
        }

        //Can't place towers on the road

        if(_map.getTile(Std.int(xPos / 8), Std.int(yPos / 8)) == 0) {
            // 何かあるので配置できない
            // 失敗SE再生
            FlxG.sound.play("deny");

            // 一般メニューに戻す
            toggleMenus(General);
            return;
        }

        // 購入実行
        // タワーを追加する
        _towerGroup.add(new Tower(xPos, yPos, towerPrice));

        // After the first tower is bought, sell mode becomes available.

        if(_sellButton.visible == false) {
            _sellButton.visible = true;
        }


        // 初めての購入であればチュートリアルテキストを表示する
        if(_tutText.visible == false && _towerGroup.length == 1) {
            _tutText.visible = true;
        }

        FlxG.sound.play("build");

        // お金を減らす
        money -= towerPrice;
        // 価格上昇
        towerPrice += Std.int(towerPrice * 0.3);
        // 購入ボタンのテキスト更新
        _towerButton.text = "Buy [T]ower ($" + towerPrice + ")";
        toggleMenus(General);
    }

    /**
	 * The select sound gets played from a lot of places, so it's in a convenient function.
	 */
    private function playSelectSound():Void {
        FlxG.sound.play("select");
    }

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

    /**
     * アナウンステキストのフェードアウト
     */
    private function hideText(Tween:FlxTween):Void {
        FlxTween.tween(_centerText, { x: FlxG.width }, 2, { ease: FlxEase.expoIn });
    }

    /**
     * 次のWave開始
     */
    private function spawnWave():Void {
        if(_gameOver) {
            return;
        }

        // Wave数を増やす

        wave ++;
        // Wave開始演出
        announceWave();

        // 出現する敵は 5 + Wave 数
        enemiesToKill = 5 + wave;
        enemiesToSpawn = enemiesToKill;

        _nextWaveButton.visible = false;

        _enemyText.visible = true;
        _enemyText.size = 16;
    }


    /**
     * 敵を生み出す
     **/
    private function spawnEnemy():Void {

        // 敵の残り数を減らす
        enemiesToSpawn--;

        // 敵を初期化
        var enemy:Enemy = enemyGroup.recycle(Enemy);
        enemy.init(_enemySpawnX, _enemySpawnY);

        // 敵をパスで動かす(見つからなかった場合はnull)
        var pList:Array<FlxPoint> = _map.findPath(
            FlxPoint.get(_enemySpawnX, _enemySpawnY), // 開始座標
            FlxPoint.get(_goalX + 5, _goalY + 5),     // 終了座標
            true,                                     // 重複を削除(デフォルト:true)
            false,                                    // 障害物を斜め移動することを許可する(デフォルト:false)
            true                                      // 斜め移動するための追加タイルが必要か(デフォルト:true)
        );
        enemy.followPath(pList);

        // 生成カウンタを初期化
        _spawnCounter = 0;
    }

    /**
	 * Called when you lose. Of course!
	 */
    private function loseGame():Void {
        _gameOver = true;

        enemyGroup.kill();
        towerIndicators.kill();
        _towerGroup.kill();
        _upgradeMenu.kill();
        _towerRange.kill();

        announceWave(true);

        _towerButton.text = "[R]estart";
        _towerButton.onDown.callback = resetCallback.bind(false);

        FlxG.sound.play("gameover");
    }

    /**
	 * Called either when building, or upgrading, a tower.
	 */
    private function updateRangeSprite(Center:FlxPoint, Range:Int):Void {
        _towerRange.setPosition(Center.x - Range, Center.y - Range);
        _towerRange.makeGraphic(Range * 2, Range * 2, FlxColor.TRANSPARENT);

        // Using and re-using a static sprite like this reduces garbage creation.

        RANGE_SPRITE = new Sprite();
        RANGE_SPRITE.graphics.beginFill(0xFFFFFF);
        RANGE_SPRITE.graphics.drawCircle(Range, Range, Range);
        RANGE_SPRITE.graphics.endFill();

        _towerRange.pixels.draw(RANGE_SPRITE);

        #if !(cpp || neko || js)
		_towerRange.blend = BlendMode.INVERT;
        #else
		_towerRange.alpha = 0.5;
		#end

        _towerRange.visible = true;
    }

    /**
	 * Called when the user attempts to update range. If they have enough money, the upgradeRange() function
	 * for this tower is called, and the money is decreased.
	 */
    private function upgradeRangeCallback():Void {
        if(!_upgradeMenu.visible) {
            return;
        }

        if(money >= _towerSelected.range_PRIZE) {
            money -= _towerSelected.range_PRIZE;
            _towerSelected.upgradeRange();
            upgradeHelper();
        }
    }

    /**
	 * Called when the user attempts to update damage. If they have enough money, the upgradeDamage() function
	 * for this tower is called, and the money is decreased.
	 */
    private function upgradeDamageCallback():Void {
        if(!_upgradeMenu.visible) {
            return;
        }

        if(money >= _towerSelected.damage_PRIZE) {
            money -= _towerSelected.damage_PRIZE;
            _towerSelected.upgradeDamage();
            upgradeHelper();
        }
    }

    /**
	 * Called when the user attempts to update fire rate. If they have enough money, the upgradeFirerate() function
	 * for this tower is called, and the money is decreased.
	 */
    private function upgradeFirerateCallback():Void {
        if(!_upgradeMenu.visible) {
            return;
        }

        if(money >= _towerSelected.firerate_PRIZE) {
            money -= _towerSelected.firerate_PRIZE;
            _towerSelected.upgradeFirerate();
            upgradeHelper();
        }
    }

    /**
	 * Called after an upgrade. Updates button text, plays a sound, and sets the upgrade bought flag to true.
	 */
    private function upgradeHelper():Void {
        updateUpgradeLabels();
        playSelectSound();

        if(_tutText.visible) {
            _tutText.visible = false;
        }
    }

    /**
	 * Update button labels for upgrades, and makes sure the range indicator sprite is updated.
	 */
    private function updateUpgradeLabels():Void {
        _rangeButton.text = "Range (" + _towerSelected.range_LEVEL + "): $" + _towerSelected.range_PRIZE;
        _damageButton.text = "Damage (" + _towerSelected.damage_LEVEL + "): $" + _towerSelected.damage_PRIZE;
        _firerateButton.text = "Firerate (" + _towerSelected.firerate_LEVEL + "): $" + _towerSelected.firerate_PRIZE;

        updateRangeSprite(_towerSelected.getMidpoint(), _towerSelected.range);
    }

    /**
	 * Controls how money is handled. Setting money automatically "balloons" the money HUD indicator.
	 */
    public var money(get, set):Int;

    private function get_money():Int {
        #if debug
		if (MONEY_CHEAT) return 0x7FFFFFFF;
		#end
        return _money;
    }

    private function set_money(NewMoney:Int):Int {
        #if debug
		if (MONEY_CHEAT) return _money;
		#end
        _money = NewMoney;
        _moneyText.text = "$: " + _money;
        _moneyText.size = 16;

        return _money;
    }
}
