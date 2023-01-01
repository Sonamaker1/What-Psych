import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;

class ModchartTween extends VarTween{
    function new(options:TweenOptions, ?manager:FlxTweenManager)
    {
        super(options, manager);
    }

	override function update(elapsed:Float):Void
	{
		//JUST STOP UPDATING BRUH CHILL
		if (active){
			var delay:Float = (executions > 0) ? loopDelay : startDelay;
	
			// Leave properties alone until delay is over
			if (_secondsSinceStart < delay)
				super.update(elapsed);
			else
			{
				// Wait until the delay is done to set the starting values of tweens
				if (Math.isNaN(_propertyInfos[0].startValue))
					setStartValues();
	
				super.update(elapsed);
	
				if (active)
					for (info in _propertyInfos)
						Reflect.setProperty(info.object, info.field, info.startValue + info.range * scale);
			}
		}
	}
		
    override function finish():Void
	{
		executions++;

		if (onComplete != null)
			onComplete(this);

		var type = type & ~FlxTweenType.BACKWARD;

		if (type == FlxTweenType.PERSIST || type == FlxTweenType.ONESHOT)
		{
			onEnd();
			_secondsSinceStart = duration + startDelay;

			if (type == FlxTweenType.ONESHOT && manager != null)
			{
				manager.remove(this);
			}
		}

		if (type == FlxTweenType.LOOPING || type == FlxTweenType.PINGPONG)
		{
			if(active){
				_secondsSinceStart = (_secondsSinceStart - _delayToUse) % duration + _delayToUse;
				scale = Math.max((_secondsSinceStart - _delayToUse), 0) / duration;

				if (ease != null && scale > 0 && scale < 1)
				{
					scale = ease(scale);
				}

				if (type == FlxTweenType.PINGPONG)
				{
					backward = !backward;
					if (backward)
					{
						scale = 1 - scale;
					}
				}
                restart();
            }
		}
	}
}