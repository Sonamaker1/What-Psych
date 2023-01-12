game.members[1].loadGraphic(Paths.image('menuBGBlue'));
game.members[1].alpha=0.6;
game.members[1].color=0xFF555555;

game.members.remove(game.gfDance);
game.titleTextColors=[0xFFFFFFFF, 0xFFFFFF00];

var screenWidth = FlxG.width;
var screenHeight = FlxG.height;
game.logoBl.screenCenter();

//funk.makeLuaSprite('bgOverlay','menuBGBlue', 0, 0);

//I took this from freestockfootagearchive.com lmao:
funk.makeAnimatedLuaSprite('NewBG', 'frames', -screenWidth*0.2, -screenHeight*0.2);
funk.addAnimationByPrefix('NewBG', 'loop', 'thumb', 12, true);
funk.scaleObject("NewBG",2, 2);
funk.addLuaSprite("NewBG",true);

var bg = game.modchartSprites.get("NewBG");
//var bgover= game.modchartSprites.get("bgOverlay");
game.members.remove(bg);
game.insert(1,bg);
//game.insert(0,bgover);

trace(GameStages);
GameStages.set("onBeatHit",{func:function(beat:Int)
{
	trace("LOL "+beat);
}
});
trace(GameStages);
