import("flixel.addons.transition.FlxTransitionableState");
import("MainMenuState");
GameStages.set("update",{func:function()
{
    if(FlxG.keys.justPressed.R){
        var mus:MusicBeatState = new CustomBeatState("MyCustomState");
        if(mus!=null){
            MusicBeatState.switchState(mus);
        }
    }
    if (controls.BACK)
    {
        selectedSomethin = true;
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new MainMenuState());
    }
}});

GameStages.set("createPost",{func:function()
{
    game.cameras = FlxG.cameras;
}});

//Make the Yellow Background:
funk.makeLuaSprite('NewBG', '', -FlxG.width*0.2, -FlxG.height*0.2);
funk.makeGraphic('NewBG', 2,2,'0xFFF0FF0B');
funk.scaleObject("NewBG", FlxG.width, FlxG.height);
funk.addLuaSprite("NewBG", true);

//Make the text
var categoryText = new FlxText(775, 25, 0, "Custom Menu!", 32);
categoryText.setFormat(Paths.font("vcr.ttf"), 64, 0xFF000000, FlxAxes.CENTER, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
categoryText.screenCenter(FlxAxes.XY);
game.add(categoryText);