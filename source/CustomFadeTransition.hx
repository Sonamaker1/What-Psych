package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;

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

class CustomFadeTransition extends MusicBeatSubstate {
	public var curMod ="";
	var instance:MusicBeatSubstate;
	#if hscript
	public static var funk:FunkinUtil;
	public static var gameStages:Map<String,FunkyFunct>;
	public var hscript:HScript = null;
	public static var iconMap:Map<Alphabet,FlxSprite> = new Map<Alphabet,FlxSprite>();
	
	public function initHaxeModule()
	{
		
		hscript = null; //man I hate this
		//TODO: make a destroy function for hscript interpreter
		try{
			if(hscript == null)
			{
				trace('initializing haxe interp for StoryMenuState');
				hscript = new HScript(true, gameStages); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
				hscript.interp.variables.set('game', this);
				hscript.interp.variables.set('funk', funk);
				hscript.interp.variables.set('CustomFadeTransition', CustomFadeTransition);
				hscript.interp.variables.set('iconMap', iconMap);
			}
		}catch(err){
			trace("Failed to intialize HScript (CustomFadeTransition)");
		}
	}
	public function startHScript(name:String){
		try{
			initHaxeModule();
			var y:String = Paths.getTextFromFile(name);
			hscript.execute(y);
		}
		catch(err){
			trace(err);
		}
	}

	public function quickCallHscript(event:String,args:Array<Dynamic>){
		callStageFunctions(event,args,gameStages);
	}
	#end

	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var transitionWidth:Int = FlxG.width;
	var transitionHeight:Int = FlxG.width;
	var duration:Float = 0.0;
	var useDefault:Bool = true;
	public static var defaultTransition = true;

	public function new(duration:Float, isTransIn:Bool) {
		super();
		#if hscript
		gameStages = new Map<String,FunkyFunct>();
		instance = this;
		//funk = new PlayState.FunkinUtil(instance, false, true);
		#end
		this.duration = duration;
		this.isTransIn = isTransIn;
		startHScript("data/CustomTransition.hx");
		
		
		var zoom:Float = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		if(hscript != null)
		{
			hscript.interp.variables.set("zoom",zoom);
			hscript.interp.variables.set("width",width);
			hscript.interp.variables.set("height",height);
		}
		
		quickCallHscript("create",[]);
		
		if(useDefault){
			transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
			//scaling is less memory expensive
			transGradient.scale.set(width, 1); // Thanks Ne_Eo!
			transGradient.updateHitbox();transGradient.scrollFactor.set();
			add(transGradient);

			transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
			transBlack.scrollFactor.set();
			add(transBlack);

			transGradient.x -= (width - FlxG.width) / 2;
			transBlack.x = transGradient.x;

			if(isTransIn) {
				transGradient.y = transBlack.y - transBlack.height;
				FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
					onComplete: function(twn:FlxTween) {
						close();
					},
				ease: FlxEase.linear});
			} else {
				transGradient.y = -transGradient.height;
				transBlack.y = transGradient.y - transBlack.height + 50;
				leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
					onComplete: function(twn:FlxTween) {
						if(finishCallback != null) {
							finishCallback();
						}
					},
				ease: FlxEase.linear});
			}

			if(nextCamera != null) {
				transBlack.cameras = [nextCamera];
				transGradient.cameras = [nextCamera];
			}
		}
		quickCallHscript("createPost",[]);
		
		nextCamera = null;
	}

	override function update(elapsed:Float) {
		if(useDefault){
			if(isTransIn) {
				transBlack.y = transGradient.y + transGradient.height;
			} else {
				transBlack.y = transGradient.y - transBlack.height;
			}
		}
		quickCallHscript("update",[elapsed]);
		super.update(elapsed);
		quickCallHscript("updatePost",[elapsed]);
		if(useDefault){
			if(isTransIn) {
				transBlack.y = transGradient.y + transGradient.height;
			} else {
				transBlack.y = transGradient.y - transBlack.height;
			}
		}
	}

	override function destroy() {
		quickCallHscript("destroy",[]);
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		PlayState.FunkinUtil.isSubstate = false;
		super.destroy();
	}
}
