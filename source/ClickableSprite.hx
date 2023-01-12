package;

import flixel.FlxSprite;

using StringTools;

class ClickableSprite extends AttachedSprite
{
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

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super(file, anim, library, loop);	
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		isHovered = FlxG.mouse.overlaps(this);
		
		if (isHovered) {
			try{
				clicked=Reflect.getProperty(FlxG.mouse,type);
			}
			catch(err){
				trace("invalid type");
			}
            if (clicked) {
                sprite.setPosition(FlxG.mouse.getPosition().x - sprite.width / 2, FlxG.mouse.getPosition().y - sprite.height / 2);
            }
        }
	}
}
