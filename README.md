# WhatEngine
Fork of Psych Engine 

This engine fork is mainly for educational use and proof-of-concept menu UI edits, please do not use it for large mods. It is currently a bit messy but I'm still learning how to make it better lol.

I'd love to see what you make with this! More updates are on the way for all the editor state menus (and possibly playstate).

## Credits

- Special Thanks to [Ne_Eo](https://twitter.com/Ne_Eo_Twitch) for the new import function!

## Default supported hscript menus:
- mods/Your Mod/data/TitleStateAddons.hx

- mods/Your Mod/data/MainMenuAddons.hx

- mods/Your Mod/data/StoryMenuAddons.hx

- mods/Your Mod/data/FreeplayAddons.hx

- mods/Your Mod/data/CreditsAddons.hx

## Custom states (can be named anything)
- mods/Your Mod/data/AnyNameYouWant.hx
```haxe
import("CustomBeatState");

var mus:MusicBeatState = new CustomBeatState("MyCustomState");
if(mus!=null){
    MusicBeatState.switchState(mus);
}
```
       



## Overriding existing states (requires two files):
### Freeplay Menu Override Example
- mods/Your Mod/data/FreeplayAddons.hx
```haxe
import("flixel.addons.transition.FlxTransitionableState");

//If you see red flash on screen something went wrong
funk.makeLuaSprite('NewBG', '', -FlxG.width*0.2, -FlxG.height*0.2);
funk.makeGraphic('NewBG', 2,2,'0xFFFB0F0B');
funk.scaleObject("NewBG", FlxG.width, FlxG.height);
funk.addLuaSprite("NewBG", true);


import("MusicBeatState");
import("LoadingState");
import("CustomBeatState");
var mus:MusicBeatState = new CustomBeatState("MyCustomState");
if(mus!=null){
    import("CustomFadeTransition");
    FlxTransitionableState.skipNextTransIn = true;
    LoadingState.loadAndSwitchState(mus);
}
```

- mods/Your Mod/data/MyCustomState.hx
```haxe
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
    //IMPORTANT, cameras are not set by default:
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
```



