# WhatEngine 

<table>
  <tr>
    <td><img src="https://github.com/Sonamaker1/What-Psych/blob/main/art/WhatTitle.png?raw=true" width="400" /> 
</td>
    <td><p>This engine fork is mainly for educational use and proof-of-concept menu UI edits, please do not use it for large mods.</p> <p>It is currently a bit messy but I'm still learning how to make it better lol.</p><p>I'd love to see what you make with this! More updates are on the way for all the editor state menus (and possibly playstate).
</p></td>
  </tr>
</table>


## Credits

- Special Thanks to [Ne_Eo](https://twitter.com/Ne_Eo_Twitch) for the new import function!
- Special Thanks to [Juno](https://twitter.com/anilmky_nikko) for the What Engine logo!

## Default supported hscript menus:
- mods/Your Mod/states/AchievementsMenuAddons.hx

- mods/Your Mod/states/CreditsAddons.hx

- mods/Your Mod/states/CustomBeatAddons.hx

- mods/Your Mod/states/FreeplayAddons.hx

- mods/Your Mod/states/MainMenuAddons.hx

- mods/Your Mod/states/options.NoteOffsetAddons.hx

- mods/Your Mod/states/options.OptionsAddons.hx

- mods/Your Mod/states/PlayAddons.hx

- mods/Your Mod/states/StoryMenuAddons.hx

- mods/Your Mod/states/TitleAddons.hx

- mods/Your Mod/states/ErrorState.hx

- mods/Your Mod/states/FirstState.hx

## Custom states (can be named anything)
- mods/Your Mod/states/AnyNameYouWant.hx
```haxe
import("CustomBeatState");

var mus:MusicBeatState = new CustomBeatState("AnyNameYouWant");
if(mus!=null){
    MusicBeatState.switchState(mus);
}
```
       



## Overriding existing states (requires two files):
### Freeplay Menu Override Example
- mods/Your Mod/states/FreeplayAddons.hx
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

- mods/Your Mod/states/MyCustomState.hx
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

## What the Funk??
The funk variable is a class instance that attempts to cover some of the functions you may be used to seeing in lua, but make them all accessible to hscript. They work almost identically. 

Example:
lua:
`makeLuaSprite('bgOverlay','curveThing', -100, -200)`

hscript:
`funk.makeLuaSprite('bgOverlay','curveThing', -100, -200);`

### Game
The game variable is the instance of the current menu you are on. So to add a sprite or text to the screen you may use game.add() and Reflect functions can be used on the game object as well.

### Errors:
Hscript-related errors are silently printed in the console for now, an upcoming update will allow window pop ups for quicker access to error logs.
