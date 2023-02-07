/*
funk.makeLuaSprite('NewBG', 'titleScreenBG', -FlxG.width*0.2, -FlxG.height*0.2);
funk.makeGraphic('NewBG', 2,2,'0xFF000000');
funk.scaleObject("NewBG", FlxG.width, FlxG.height);
funk.addLuaSprite("NewBG", true);
*/

import("MusicBeatState");

import("CustomBeatState");
trace(MusicBeatState);
trace(CustomBeatState);
var mus:MusicBeatState = new CustomBeatState("MyCustomState");
trace(mus);
if(mus!=null){
    MusicBeatState.switchState(mus);
}