package;

import flixel.FlxSprite;
import MusicBeatState.FunkyFunct;
import flixel.math.FlxPoint;
import flixel.FlxG;

using StringTools;

class ClickableSprite extends FlxSprite
{
	public static var functs:Map<String,FunkyFunct>;
	
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public var isHovered = false;
	public var clicked = false;
	public var type = "pressed";

	public function callSpriteFunctions(event:String,args:Array<Dynamic>,gameStages:Map<String,FunkyFunct>){
		try{
			var ret = gameStages.get(event);
			if(ret != null){
				Reflect.callMethod(null, ret.func, args);
			}
		}
		catch(err){
			trace("\n["+event+"] Stage Function Error: " + err);
		}
	}

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super();
		functs = new Map<String,FunkyFunct>();
		if(anim != null) {
			frames = Paths.getSparrowAtlas(file, library);
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		} else if(file != null) {
			loadGraphic(Paths.image(file));
		}
		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if(copyAngle)
				angle = sprTracker.angle + angleAdd;

			if(copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if(copyVisible) 
				visible = sprTracker.visible;
		}

		isHovered = FlxG.mouse.overlaps(this);
		
		if (isHovered) {
			callSpriteFunctions("hovered",[this, FlxG.mouse.getPosition()],functs);
                
			try{
				clicked=Reflect.getProperty(FlxG.mouse,type);
			}
			catch(err){
				trace("invalid type");
			}
            if (clicked) {
				callSpriteFunctions("clicked",[this, FlxG.mouse.getPosition()],functs);
            	//sprite.setPosition(FlxG.mouse.getPosition().x - sprite.width / 2, FlxG.mouse.getPosition().y - sprite.height / 2);
            }
        }
	}
}

