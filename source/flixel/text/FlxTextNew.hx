// Fix From: https://github.com/HaxeFlixel/flixel/pull/2656
// Hi Neo, thanks for this lol
package flixel.text;

import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.atlas.FlxNode;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRange;
import openfl.Assets;

// TODO: think about filters and text

/**
 * Extends FlxSprite to support rendering text. Can tint, fade, rotate and scale just like a sprite. Doesn't really animate
 * though. Also does nice pixel-perfect centering on pixel fonts as long as they are only one-liners.
 */
class FlxTextNew extends FlxText
{
	static inline var VERTICAL_GUTTER:Int = 4;

	override function regenGraphic():Void
	{
		if (textField == null || !_regen)
			return;

		var oldWidth:Int = 0;
		var oldHeight:Int = VERTICAL_GUTTER;

		if (graphic != null)
		{
			oldWidth = graphic.width;
			oldHeight = graphic.height;
		}

		var newWidth:Int = Math.ceil(textField.width);
		// Account for gutter
		var newHeight:Int = Math.ceil(textField.textHeight) + VERTICAL_GUTTER;

		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight == 0)
		{
			newHeight = oldHeight;
		}

		if (oldWidth != newWidth || oldHeight != newHeight)
		{
			// Need to generate a new buffer to store the text graphic
			height = newHeight;
			var key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);

			if (_hasBorderAlpha)
				_borderPixels = graphic.bitmap.clone();
			frameHeight = newHeight;
			textField.height = height * 1.2;
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
}