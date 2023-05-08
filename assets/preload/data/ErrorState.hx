import ("MainMenuState");
import ("MusicBeatState");
import ("NewState");
import ("flixel.util.FlxAxes");
import ("flixel.util.FlxColor");
import ("flixel.text.FlxText");
function update(elapsed) {
    if (controls.BACK) {
        MusicBeatState.switchState(new MainMenuState());
    }
    if (controls.ACCEPT) {
        MusicBeatState.switchState(new NewState(lastStateName));
    }
}

function create(){
    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    game.add(bg);
    warnText = new FlxText(0, 0, FlxG.width,
        errMsg,
        32);
    warnText.setFormat("VCR OSD Mono", 32, 0xFFFFFFFF, "center");
    warnText.screenCenter(FlxAxes.X);
    game.add(warnText);


    moreText = new FlxText(0, 50, FlxG.width,
        errDetails,
        32);
    moreText.setFormat("VCR OSD Mono", 16, 0xFFFFFFFF, "left");
    moreText.screenCenter(FlxAxes.X);
    game.add(moreText);
}
