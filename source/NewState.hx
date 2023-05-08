import llua.Lua.Lua_helper;
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
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;

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


import Type.ValueType;


class NewState extends PlayState
{
	public static var gameStages:Map<String,FunkyFunct>;
	public static var hscript:HScript = null;
	public var curMod ="";
	public static var startingVariables:Map<String, Null<Dynamic>> = null;
	public static var lastState = "";
	public static var lastMod = "";
	public function setUpVars(){
		#if (haxe >= "4.0.0")
		boyfriendMap = new Map();
		dadMap = new Map();
		gfMap = new Map();
		variables = new Map();
		modchartTweens = new Map();
		modchartSprites = new Map();
		modchartTimers = new Map();
		modchartSounds = new Map();
		modchartTexts = new Map();
		modchartSaves = new Map();
		#else
		boyfriendMap = new Map<String, Boyfriend>();
		dadMap = new Map<String, Character>();
		gfMap = new Map<String, Character>();
		variables = new Map<String, Dynamic>();
		modchartTweens = new Map<String, FlxTween>();
		modchartSprites = new Map<String, ModchartSprite>();
		modchartTimers = new Map<String, FlxTimer>();
		modchartSounds = new Map<String, FlxSound>();
		modchartTexts = new Map<String, ModchartText>();
		modchartSaves = new Map<String, FlxSave>();
		#end
	}

	public function initHaxeModule()
	{
		
		hscript = null; //man I hate this but idk how else to do it lol
		try{
			if(hscript == null)
			{
				trace('initializing haxe interp for CustomBeatState');
				hscript = new HScript(); 
				hscript.interp.variables.set('game', cast(this,MusicBeatState));
				//hscript.interp.variables.set('funk', funk);
				hscript.interp.variables.set('controls', controls);
				hscript.interp.variables.set('stringMap', new Map<String, Array<String>>() );
				hscript.interp.variables.set('alphabetMap', new Map<String, Alphabet>() );

				//Thanks Neo!
				hscript.interp.variables.set("import", function(pkg) {
					var a = pkg.split(".");
					var e = Type.resolveEnum(pkg);
					hscript.interp.variables.set(a[a.length-1], e!=null?e:Type.resolveClass(pkg));
				});
				if(startingVariables!=null){
					for(v in startingVariables.keys()){
						hscript.interp.variables.set(v, startingVariables.get(v));
					}					
					startingVariables=null;
				}
				
				luaArray.push(new FunkinLua("assets/data/blank.lua"));
				trace(Lua_helper.callbacks.keys());
				for(v in Lua_helper.callbacks.keys()){
					NewState.hscript.interp.variables.set(v,  
						Lua_helper.callbacks.get(v)
					);	
					
					/*	function(a,?b:Null<Dynamic>,?c:Null<Dynamic>,?d:Null<Dynamic>,?e:Null<Dynamic>,?f:Null<Dynamic>){
							trace(v);
							try{
								Reflect.callMethod(luaArray[0], Lua_helper.callbacks.get(v), [a,b,c,d,e,f]);
							}	
							catch (err){
								trace(err);
							}
						}
					);*/
				}
			}
		}catch(err){
			trace("Failed to intialize HScript (CustomBeatState)");
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
			trace(err);
		}
	}

	override public function runHScript(name:String, hscript:FunkinLua.HScript, ?modFolder:String="", ?isCustomState:Bool=false){
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
		catch(e:haxe.Exception) {
            trace('error parsing: ' + e.message);
			customErrorFunction(e.message,e.details());
			return;
        }
		catch(e:Dynamic){
			trace('error parsing: ' + e);
		}
	}

	public function quickCallHscript(event:String,args:Array<Dynamic>){
		try{
			var ret = hscript.variables.get(event);
			if(ret != null){
				Reflect.callMethod(null, ret, args);
			}
		}
		catch(err){
			trace("\n["+event+"] Stage Function Error: " + err);
		}
	}

	public static function customErrorFunction(message:String,details:String):Void{
		trace("\n[DISPLAYING ERROR STATE]\n");
		
		Paths.hscriptModDirectory = "";
		var errorState = new NewState("ErrorState", [
			"lastStateName"=>"NewState",
			"errMsg"=>message,
			"errDetails"=>details
		]);
		MusicBeatState.switchState(errorState);
	};

	public var name:String = 'unnamed';
	public static var instance:NewState;

	override function create()
	{
		FlxG.mouse.visible=true;
		curMod = Paths.hscriptModDirectory;
		
		trace("creation");
		instance = this;
		#if hscript
		gameStages = new Map<String,FunkyFunct>();
		//funk = new PlayState.FunkinUtil(instance);
		#end
		PlayState.instance=instance;
		setUpVars();
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camGame.bgColor = FlxColor.fromRGB(2, 3, 5);

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		super.bypass_create();
		//trace("create super");
		//PlayState.instance.callOnLuas('create', [name]);
		#if hscript
		initHaxeModule();
		runHScript("data/"+name+".hx",hscript, curMod, true);
		#end
		quickCallHscript("create",[]);	
		
		
	}
	
	public function new(nameInput:String = null, ?startingVars:Map<String,Dynamic>) {
        super();
		if(nameInput != null) {
            name = nameInput;
			if(nameInput!="ErrorState"){
				lastState = nameInput;
				lastMod = Paths.hscriptModDirectory;
			}
        }
		if(startingVars !=null){
			//startingVariables = startingVars; //Doesn't work
			startingVariables = [for( k in startingVars.keys() ) k => startingVars.get(k)]; 
		}
    }

	//override function closeSubState(){super.bypass_closeSubState();}
	//override function create(){super.bypass_create();}
	//override function destroy(){super.bypass_destroy();}
	override function onFocus(){super.bypass_onFocus();}
	override function onFocusLost(){super.bypass_onFocusLost();}
	override function openSubState(SubState:FlxSubState){super.bypass_openSubState(SubState);}
	
	override function stepHit(){
		quickCallHscript("pre_stepHit",[]);
		super.bypass_stepHit();
		NewState.hscript.interp.variables.set('curStep', instance.curStep);
		quickCallHscript("stepHit",[]);
	}

	override function beatHit()
	{
		quickCallHscript("pre_beatHit",[]);
		super.bypass_beatHit();
		NewState.hscript.interp.variables.set('curBeat', instance.curBeat);
		quickCallHscript("beatHit",[]);
		//FlxG.log.add('beat');
	}
	
	override function update(elapsed:Float)
	{
		quickCallHscript("update",[elapsed]);
		super.bypass_update(elapsed);
		quickCallHscript("updatePost",[elapsed]);
	}


	override function destroy() {
		FlxG.mouse.visible=false;
		FlxG.mouse.cursorContainer.alpha = 1;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		quickCallHscript("stateDestroy",[]);
		luaArray = [];
		super.bypass_destroy();
	}
	
}
