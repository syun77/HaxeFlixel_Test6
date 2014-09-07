package;

import flixel.text.FlxText;
import flixel.text.FlxText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;

/**
 * カスタムボタン
 **/
class Button extends FlxButton {

    /**
     * Minimalistボタンを生成します。黒い背景に白いテキストのボタンとなります
     * @param X      座標(X)
     * @param Y      座標(Y)
     * @param Label  ラベルテキスト
     * @param OnDown ボタン押下時のコールバック関数
     * @param Width  ボタンの幅
     **/
    public function new(X:Int = 0, Y:Int = 0, Label:String, ?OnDown:Void -> Void, Width:Int = -1) {

        // 座標・ラベル・コールバックを設定
        super(X, Y, Label, OnDown);

        // 幅の指定を反映
        if(Width > 0) {
            width = Width;
        }
        else {
            // フォントサイズは「7」とする
            width = Label.length * 7;
        }

        // 高さは20固定
        height = 20;
        label.alpha = 1;
        set_status(status);

        makeGraphic(Std.int(width), Std.int(height), 0);
    }

    /**
	 * Override set_status to change how highlight / normal state looks.
	 */
    override private function set_status(Value:Int):Int {
        if(label != null) {
            if(Value == FlxButton.HIGHLIGHT) {
                #if !mobile // "highlight" doesn't make sense on mobile
                label.color = FlxColor.WHITE;
                label.borderStyle = FlxText.BORDER_OUTLINE_FAST;
                label.borderColor = FlxColor.BLACK;
                #end
            }
            else {
                label.color = FlxColor.BLACK;
                label.borderStyle = FlxText.BORDER_OUTLINE_FAST;
                label.borderColor = FlxColor.WHITE;
            }
        }
        return status = Value;
    }
}