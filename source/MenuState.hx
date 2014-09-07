package;

import flixel.FlxSprite;
import flash.display.Sprite;
import flixel.util.FlxPoint;
import openfl.Assets;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxPoint;
import flixel.util.FlxColor;
import flixel.tile.FlxTilemap;

/**
 * タイトル画面
 **/
class MenuState extends FlxState {
    private static inline var TILE_SIZE:Int = 8;
    private static inline var START_X:Int = TILE_SIZE * 5 + 1;
    private static inline var START_Y:Int = 0;
    private static inline var END_X:Int = 34 * TILE_SIZE + 2;
    private static inline var END_Y:Int = 29 * TILE_SIZE;

    private var _enemy:Enemy;
    private var _map:FlxTilemap;

    /**
	 * Creates the title menu screen.
	 */

    override public function create():Void {
        // オリジナルのマウスカーソルを設定
        FlxG.mouse.load("images/mouse.png");
        #if flash
        // 反転描画を有効にする (Flashのみ)
		FlxG.mouse.cursorContainer.blendMode = BlendMode.INVERT;
		#end

        FlxG.cameras.bgColor = FlxColor.WHITE;

        // マップデータの読み込み
        // CSVファイルを読み込みタイル画像を設定する
        // タイル情報は、
        //  0: 通過できないタイル
        //  1: 通過可能なタイル
        // となる
        _map = new FlxTilemap();
        _map.loadMap(Assets.getText("tilemaps/menu_tilemap.csv"), Reg.tileImage);

        // ゲームタイトル表示
        var headline:FlxText = new FlxText(0, 40, FlxG.width, "Minimalist TD", 16);
        headline.alignment = "center";

        // ゲームクレジット
        var credits:FlxText = new FlxText(2, FlxG.height - 12, FlxG.width, "Made in 48h for Ludum Dare 26 by Gama11");

        // 開始ボタンの生成
        var playButton:Button = new Button(0, Std.int(FlxG.height / 2), "[P]lay", playButtonCallback);
        playButton.x = Std.int((FlxG.width - playButton.width) / 2);



        // 敵を配置して繰り返し画面を横断させる
        _enemy = new Enemy(START_X, START_Y);
        enemyFollowPath();

        // オブジェクトを登録
        add(_map);
        add(headline);
        add(credits);
        add(playButton);
        add(_enemy);

        super.create();
    }

    /**
     * 開始ボタンを押した
     **/
    private function playButtonCallback():Void {
        // メインゲームを開始する
        FlxG.switchState(new PlayState());
    }

    /**
     * 更新
     **/
    override public function update():Void {

        // 敵がパスの終端に達したかどうかをチェックする
        if(_enemy.y >= 28 * TILE_SIZE) {
            // 終端なので、パスの開始に初期化する
            enemyFollowPath();
        }

        // Pキーでゲームを開始する
        if(FlxG.keys.justReleased.P) {
            playButtonCallback();
        }

        super.update();
    }

    /**
     * 敵の移動パスを開始する
     **/
    public function enemyFollowPath():Void {
        _enemy.followPath(_map.findPath(FlxPoint.get(START_X, START_Y), FlxPoint.get(END_X, END_Y)));
    }

    /**
     * 破棄する
     **/
    override public function destroy():Void {
        _enemy = null;
        _map = null;

        super.destroy();
    }
}