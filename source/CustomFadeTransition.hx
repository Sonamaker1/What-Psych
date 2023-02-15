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
	var instance:CustomFadeTransition;
	#if hscript
	public static var funk:FunkinUtil;
	public static var gameStages:Map<String,FunkyFunct>;
	public static var hscript:HScript = null;
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
				hscript.interp.variables.set('game', cast(this,MusicBeatSubstate));
				hscript.interp.variables.set('funk', funk);
				hscript.interp.variables.set('CustomFadeTransition', CustomFadeTransition);
				hscript.interp.variables.set('iconMap', iconMap);
			}
		}catch(err){
			trace("Failed to intialize HScript (CustomFadeTransition)");
		}
	}
	#end
	public function quickCallHscript(event:String,args:Array<Dynamic>){
		#if hscript
		callStageFunctions(event,args,gameStages);
		#end
	}

	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var transitionWidth:Int = FlxG.width;
	var transitionHeight:Int = FlxG.width;
	
	public static var defaultTransition = true;

	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
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
		nextCamera = null;
	}

	override function update(elapsed:Float) {
		if(isTransIn) {
			transBlack.y = transGradient.y + transGradient.height;
		} else {
			transBlack.y = transGradient.y - transBlack.height;
		}
		super.update(elapsed);
		if(isTransIn) {
			transBlack.y = transGradient.y + transGradient.height;
		} else {
			transBlack.y = transGradient.y - transBlack.height;
		}
	}

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}
