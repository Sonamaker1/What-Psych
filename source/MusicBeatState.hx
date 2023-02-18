package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
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
import flixel.FlxSubState;

#if VIDEOS_ALLOWED 
#if windows
import vlc.MP4Handler;
#end
#end

#if !html5
import sys.FileSystem;
import sys.io.File;
#end

interface BeatStateInterface {
	public var camGame:FlxCamera;
	//public var members(default, null):Array<Dynamic>;
	
	private var curStep:Int;
	private var curBeat:Int;

	private var curDecStep:Float;
	private var curDecBeat:Float;
	private var controls(get, never):Controls;
	
	public function get_controls():Controls;

	public function runHScript(name:String, hscript:FunkinLua.HScript, ?modFolder:String, ?isCustomState:Bool):Void;

	public function getControl(key:String):Bool;

	//public function callStageFunctions(event:String,args:Array<Dynamic>,gameStages:Map<String,FunkyFunct>):Void;

	public var variables:Map<String, Dynamic>;
	public var modchartTweens:Map<String, FlxTween>;
	public var modchartSprites:Map<String, ModchartSprite>;
	public var modchartTimers:Map<String, FlxTimer>;
	public var modchartSounds:Map<String, FlxSound>;
	public var modchartTexts:Map<String, ModchartText>;
	public var modchartSaves:Map<String, FlxSave>;
	public var runtimeShaders:Map<String, Array<String>>;
	
	private function updateBeat():Void;

	private function updateCurStep():Void;
	public var persistentUpdate:Bool;

	//public function remove(Object:FlxBasic, ?Splice:Bool = false):FlxBasic;
	public function callOnLuas(event:String, args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic;
	

	public function stepHit():Void;

	public function beatHit():Void;

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite;
}

class MusicBeatState extends FlxUIState implements BeatStateInterface
{
	public var camGame:FlxCamera;
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

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
	//public static var gameStages:Map<String,FunkyFunct> = new Map<String,FunkyFunct>();
	

	public static var camBeat:FlxCamera;

	public function get_controls():Controls
		return PlayerSettings.player1.controls;

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
				if(isCustomState){
					MusicBeatState.switchState(new MainMenuState());
				}
			}
			hscript.execute(y);
		}
		catch(err){
			trace(err);
		}
	}


	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function openSubState(SubState:FlxSubState){
		PlayState.FunkinUtil.isSubstate=true;
		super.openSubState(SubState);
	}
	
	override function closeSubState(){
		PlayState.FunkinUtil.isSubstate=false;
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	public function onVideoEnd(filepath:String, success:Bool)
	{
		//callStageFunctions("onVideoEnd",[filepath, success]);
	}

	public function startVideo(name:String)
	{
		var filepath = Paths.video(name);
		#if VIDEOS_ALLOWED
		
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			onVideoEnd(filepath, false);
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			onVideoEnd(filepath, true);
			//startAndEnd();
			return;
		}
		#else
		#if windows
		FlxG.log.warn('Platform not supported!');
		onVideoEnd(filepath, false);
		//startAndEnd();
		return;
		#end
		#end
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
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

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}


	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
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

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.globalAntialiasing;
	}
}



class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

// New Junk Below For HScript usage lol
typedef FunkyFunct = {
    var func:Void->Void;
}