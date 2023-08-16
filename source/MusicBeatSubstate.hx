package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.system.FlxSound;
import flixel.FlxObject;
import flixel.text.FlxTextNew as FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;

#if VIDEOS_ALLOWED
#if (hxCodec >= "2.6.1") import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0") import VideoHandler as MP4Handler;
#else import vlc.MP4Handler; #end
#end

#if !html5
import sys.FileSystem;
import sys.io.File;
#end

import MusicBeatState.FunkyFunct;
import MusicBeatState.ModchartSprite;
import MusicBeatState.ModchartText;
import MusicBeatState.BeatStateInterface;


class MusicBeatSubstate extends FlxSubState implements BeatStateInterface
{
	
	public var camGame:FlxCamera;

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}
	
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	#if (haxe >= "4.0.0")
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#else
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	#end
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	

	public function runHScript(name:String, hscript:FunkinLua.HScript, ?modFolder:String="", ?isCustomState:Bool=false){
		try{
			var path:String = "mods/"+modFolder+"/"+name; // Paths.getTextFromFile(name);
			var y = '';
			//PLEASE WORK 
			if (FileSystem.exists(path)){
				trace(path);
				y = File.getContent(path);
			}else if(FileSystem.exists(Paths.modFolders(modFolder+"/"+name))){
				trace(Paths.modFolders(modFolder+"/"+name));
				y = File.getContent(path);
			}else if(FileSystem.exists(modFolder+"/"+name)){
				trace(modFolder+"/"+name);
				y = File.getContent(path);
			}else if(FileSystem.exists(Paths.modFolders(name))){
				trace(Paths.modFolders(name));
				y = File.getContent(path);
			}else{
				trace(path + "Does not exist");
				y = Paths.getTextFromFile(modFolder+"/"+name);
				/*if(isCustomState){
					MusicBeatState.switchState(new MainMenuState());
				}*/
			}
			hscript.execute(y);
		}
		catch(err){
			trace(err);
		}
	}

	public function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ?ignoreStops = true, ?exclusions:Array<String> = null):Dynamic {
		//callStageFunctions(event,args);
		return 0;
	}

	public function callStageFunctions(event:String,args:Array<Dynamic>,gameStages:Map<String,FunkyFunct>){
		try{
			var ret = gameStages.get(event);
			if(ret != null){
				//trace(event);
				Reflect.callMethod(null, ret.func, args);
				/*
				gameParameters.set("args", args);
				ret.func();*/
			}
			//trace(ret+"("+event+")");
		}
		catch(err){
			trace("\n["+event+"] Stage Function Error: " + err);
		}
	}
	
}
