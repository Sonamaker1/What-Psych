package;

#if desktop
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxTextNew as FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;
import MusicBeatState.ModchartSprite;
import MusicBeatState.ModchartText;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import PlayState.FunkinUtil;
import FunkinLua.HScript;
import FunkinLua.CustomSubstate;
import MusicBeatState.FunkyFunct;
#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
#end

using StringTools;
typedef TitleData =
{

    titlex:Float,
    titley:Float,
    startx:Float,
    starty:Float,
    gfx:Float,
    gfy:Float,
    backgroundSprite:String,
    bpm:Int
}

class InitialState extends MusicBeatState
{
	// Class was originally named "TitleFake" 
	// cause it just does all the things that TitleState sets up.
    public static var initialized:Bool = false;
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var closedState:Bool = true; //lol
	
    var titleJSON:TitleData;

	public static var updateVersion:String = '';
	
	#if hscript
	var instance:InitialState;
	public static var funk:FunkinUtil;
	public static var gameStages:Map<String,FunkyFunct>;
	public static var hscript:HScript = null;
	

	public function initHaxeModule()
	{
		
		hscript = null; //man I hate this
		//TODO: make a destroy function for hscript interpreter
		if(hscript == null)
		{
			trace('initializing haxe interp for InitialState');
			hscript = new HScript(true, gameStages); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
			hscript.interp.variables.set('game', cast(this,MusicBeatState));
			hscript.interp.variables.set('NewState', NewState);
			hscript.interp.variables.set('funk', funk);
		}
	}

	public function startHScript(name:String){
		try{
			initHaxeModule();
			var y:String = Paths.getTextFromFile(name);
			try{
				hscript.execute(y);
			}
			catch(err){
				CoolUtil.displayErr(err);
			}
		}
		catch(err){
			trace("Asset not available: [" +name + "] ");
		}
	}

	public function quickCallHscript(event:String,args:Array<Dynamic>){
		callStageFunctions(event,args,gameStages);
	}
	#end
	override public function create():Void
	{
		
		#if hscript
		gameStages = new Map<String,FunkyFunct>();
		instance = this;
		funk = new FunkinUtil(instance);
		#end

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();
        super.create();
		FlxG.save.bind('funkin' #if (flixel < "5.0.0"), 'ninjamuffin99' #end);
		ClientPrefs.loadPrefs();

		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

        Conductor.changeBPM(128.0);
		//FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);
		//Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		startHScript("states/FirstState.hx");	
        //FlxG.mouse.visible = false;
		
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		quickCallHscript('onUpdate', [elapsed]);
		
	}

}
