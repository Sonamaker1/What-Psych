package;

import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.system.FlxSound;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

import lime.graphics.opengl.*;
import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import openfl.Lib;
import openfl.text.TextField;
import openfl.geom.Rectangle;
import openfl.display.Shape;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}


	public static function displayErr(err:haxe.Exception){
		displayError(err.message,err.details());
	}

	public static function displayError(result:String,details:String){
		//var result:Dynamic = err.message;
		if(result != null) {
			#if windows 
				lime.app.Application.current.window.alert(result, 'Error on .HX script!'); 
			#end

			#if linux 
				var copyVals = ["x","y"];
				var win = Lib.application.createWindow({alwaysOnTop:true,  width: 550, height: 200 });
				var appWin = lime.app.Application.current.window;
				win.title = 'Error on .HX script!';
				win.stage.color = FlxColor.GRAY;
				for(val in Reflect.fields(lime.app.Application.current.window)){
					//trace(val);
					if(copyVals.indexOf(val)>=0){
						Reflect.setProperty(win,val,Reflect.getProperty(lime.app.Application.current.window, val));
					}
				}
				win.y+=Std.int(appWin.height/2-win.height/2);
				win.x+=Std.int(appWin.width/2-win.width/2);
				appWin.stage.addChild(Main.gameRender);
				
				
				var rect1 = new Shape ();
				rect1.graphics.beginFill(0x000000);
				rect1.graphics.drawRect (19, 19, win.width-38, 32);
				rect1.graphics.endFill();
				win.stage.addChild (rect1);
				
				var rect2 = new Shape ();
				rect2.graphics.beginFill(0xFFFFFF);
				rect2.graphics.drawRect (20, 20, win.width-40, 30);
				rect2.graphics.endFill();
				win.stage.addChild (rect2);

				var myText = new TextField ();
				myText.text = result;
				myText.wordWrap=false;
				myText.width=win.width-40;
				myText.height=30;
				myText.x=20;
				myText.y=20;
				win.stage.addChild (myText);
				
				var text1 = new TextField ();
				text1.text = details;
				text1.wordWrap=false;
				text1.width=win.width-40;
				text1.height=win.height-80;
				text1.x=20;
				text1.y=50;
				win.stage.addChild (text1);
				var cleaner:Void->Void;
				function cleanUp(){
					trace("cleaning");
					win.stage.removeChild(rect1);
					win.stage.removeChild(rect2);
					win.stage.removeChild(text1);
					win.stage.removeChild(myText);
					appWin.stage.addChild(Main.gameRender);
					win.onClose.remove(cleaner);
				}
				cleaner=cleanUp;
				
				win.onClose.add(cleaner);
			#end
			
			
			trace(details);
			return;
		}
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
}
