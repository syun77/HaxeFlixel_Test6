package;

import flash.geom.Matrix;
import flash.display.BitmapData;
import flixel.util.FlxColor;

class Reg {

    public static var PS:PlayState;

    /**
     * 24x8のタイルセット画像 (FlxTilemapで使用する)
     **/
    public static var tileImage(get, null):BitmapData;

    public static function get_tileImage():BitmapData {
        // タイルセット画像のパターンを作成
        // 白,黒,白
        var tileset:BitmapData = new BitmapData(8 * 3, 8, false, FlxColor.WHITE);
        tileset.draw(new BitmapData(8, 8, false, FlxColor.BLACK), new Matrix(1, 0, 0, 1, 8, 0));
        return tileset;
    }

    /**
	 * Returns an enemy graphic, just a square with eyes.
	 */
    public static var enemyImage(get, null):BitmapData;

    public static function get_enemyImage():BitmapData {
        var enemy:BitmapData = new BitmapData(6, 6, false, FlxColor.BLACK);
        var eye:BitmapData = new BitmapData(1, 2, false, FlxColor.WHITE);
        enemy.draw(eye, new Matrix(1, 0, 0, 1, 1, 1));
        enemy.draw(eye, new Matrix(1, 0, 0, 1, 4, 1));

        return enemy;
    }
}