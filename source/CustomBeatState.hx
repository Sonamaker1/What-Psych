#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxTextNew as FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;

import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

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

class CustomBeatState extends MusicBeatState
{
	#if hscript
	public static var funk:FunkinUtil;
	public static var gameStages:Map<String,FunkyFunct>;
	public static var hscript:HScript = null;
	public var curMod ="";
	public static var enableSwitchBack = true;
	public static var iconMap:Map<Alphabet,FlxSprite> = new Map<Alphabet,FlxSprite>();
	
	public function initHaxeModule()
	{
		
		hscript = null; //man I hate this
		//TODO: make a destroy function for hscript interpreter
		try{
			if(hscript == null)
			{
				trace('initializing haxe interp for CustomBeatState');
				hscript = new HScript(true, gameStages); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
				hscript.onParserError=function(){
					MusicBeatState.switchState(new MainMenuState());
				};
				hscript.interp.variables.set('game', cast(this,MusicBeatState));
				hscript.interp.variables.set('funk', funk);
				hscript.interp.variables.set('iconMap', iconMap);
				hscript.interp.variables.set('controls', controls);
				
			}
		}catch(err){
			trace("Failed to intialize HScript (CustomBeatState)");
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
			CoolUtil.displayErr(err);
		}
	}
	#end

	public function quickCallHscript(event:String,args:Array<Dynamic>){
		#if hscript
		callStageFunctions(event,args,gameStages);
		#end
	}

	public var name:String = 'unnamed';
	public static var instance:CustomBeatState;

	override function create()
	{
		curMod = Paths.hscriptModDirectory;
		trace("creation");
		instance = this;
		#if hscript
		gameStages = new Map<String,FunkyFunct>();
		funk = new PlayState.FunkinUtil(instance);
		#end
		super.create();
		trace("create super");
		//PlayState.instance.callOnLuas('create', [name]);
		#if hscript
		initHaxeModule();
		runHScript("data/"+name+".hx",hscript, curMod, true);
		#end
		quickCallHscript("create",[]);	
		//There is no difference here, if 
		quickCallHscript("createPost",[]);
		
	}
	
	public function new(nameinput:String)
	{
		trace("new");
		
		name = nameinput;
		super();
		trace("new super");
		
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function beatHit()
	{
		quickCallHscript("beatHit",[]);
		super.beatHit();
		quickCallHscript("beatHitPost",[]);
		//FlxG.log.add('beat');
	}
	
	override function update(elapsed:Float)
	{
		quickCallHscript("update",[elapsed]);
		super.update(elapsed);
		quickCallHscript("updatePost",[elapsed]);
	}

	override function destroy()
	{
		quickCallHscript("stateDestroy",[]);
		super.destroy();
	}
}