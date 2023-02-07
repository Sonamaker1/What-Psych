game.members[1].loadGraphic(Paths.image('menuBGBlue'));
game.members[1].alpha=0.6;
game.members[1].color=0xFF555555;


game.logoBl.loadGraphic(Paths.image('WhatTitle'));
game.members.remove(game.gfDance);
game.titleTextColors=[0xFFFFFFFF, 0xFFFFFF00];

var screenWidth = FlxG.width;
var screenHeight = FlxG.height;
game.logoBl.screenCenter();

//funk.makeLuaSprite('bgOverlay','menuBGBlue', 0, 0);

//I took this from freestockfootagearchive.com lmao:
funk.makeAnimatedLuaSprite('NewBG', 'titleScreenBG', -screenWidth*0.2, -screenHeight*0.2);
funk.addAnimationByPrefix('NewBG', 'loop', 'thumb', 12, true);
funk.scaleObject("NewBG",2, 2);
funk.addLuaSprite("NewBG",true);

var bg = game.modchartSprites.get("NewBG");
//var bgover= game.modchartSprites.get("bgOverlay");
game.members.remove(bg);
game.insert(1,bg);
//game.insert(0,bgover);


//Took this code from retrospecter v1.75 lol
var minScale:Float = 0.19; // 0.13
var toScale:Float = 1; // 0.15
var decScale:Float = 0.25;
game.logoBl.scale.set(minScale,minScale);


GameStages.set("onBeatHit",{func:function(beat:Int)
{
    if(game.logoBl != null){
        FlxTween.tween(game.logoBl.scale, {x: toScale, y: toScale}, 0.025, {ease: FlxEase.quadInOut});
    }
}
});

GameStages.set("onUpdate",
{func:
 function(elapsed:Float){
    var introMusic;
    if (introMusic != null && introMusic.playing)
        Conductor.songPosition = introMusic.time;
    else if (FlxG.sound.music != null)
    {
        Conductor.songPosition = FlxG.sound.music.time;

        // Workaround for missing a beat animation on song loop
        if (Conductor.songPosition == 0)
        {
            beatHit();
        }
    }

    if (game.logoBl != null && game.logoBl.scale.x > minScale) {
        game.logoBl.scale.x -= decScale * elapsed;
        game.logoBl.scale.y -= decScale * elapsed;
    }
}
});

