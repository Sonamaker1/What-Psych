var curAlphabet;
GameStages.set("update",{func:function(?elapsed:float)
{
    if(curAlphabet!=null){
        game.diffText.y=30+curAlphabet.y;
        game.diffText.x=570+curAlphabet.x;
        game.scoreText.y=curAlphabet.y-40;
        game.scoreBG.y=curAlphabet.y-40;
    }
    if(FlxG.keys.justPressed.E){
        MusicBeatState.switchState(new FreeplayState());
    }
}});


var aSprites=[];
import('AttachedSprite');
import('BGSprite');
game.diffText.screenCenter(FlxAxes.Y);
game.scoreBG.makeGraphic(1, 30, 0xFFFFF314); 

funk.makeLuaSprite('topBar','', -1, -200);
//funk.makeGraphic('topBar',2,2,'0xFFFFF314');
funk.makeLuaSprite('botBar','', -1, FlxG.height+60);
//funk.makeGraphic('botBar',2,2,'0xFFFFF314');
game.modchartSprites.get("topBar").scrollFactor.set(0,0);
game.modchartSprites.get("botBar").scrollFactor.set(0,0);
game.modchartSprites.get("botBar").flipY=true;
funk.scaleObject("topBar", FlxG.width+1, 30);
funk.scaleObject("botBar", FlxG.width+1, 15);

game.add(game.modchartSprites.get("topBar"));
game.insert(2,game.modchartSprites.get("botBar"));


var preview = new BGSprite(
    'screens', 40, 160, 0, 0, 
    ["dad", "hatersim", "holiday", "mom", "lemonmonster", "monsterholiday", "philly", "spookykids", "stress", "tankman", "thorns", "tutorial"], 
    false);
preview.scale.set(0.4,0.4);
preview.updateHitbox();

for(icon in game.iconArray){
    for(spr in game.grpSongs.members)
    {
        spr.distancePerItem.y=60;
        spr.x = 400;  
        spr.distancePerItem.x=0;
        //spr.changeY = false;
        if(icon!=null && icon.sprTracker == spr){
            if(spr.width>600){
                //Winter Horrorland rule
                spr.scaleWord = 0.5;
            }else{
                spr.scaleWord = 0.6;
            }

            var ut = new AttachedSprite("songTitleBG","inactive");
            
            aSprites.push(ut);
            ut.sprTracker=spr;
            //icon.sprTracker=ut;
            ut.animation.addByPrefix('active', "active", 24, false);
			ut.animation.addByPrefix('inactive', "inactive", 24, false);
			game.insert(1,ut);
            ut.scale.set(0.75,0.95);
            ut.offset.y=10;
            ut.offset.x=-425;
            iconMap.set(spr, ut);
            icon.scale.set(0.4,0.4);
            icon.offset.x=-1100+spr.width+150;
            spr.offset.x=-1100+500;//+spr.width+50;
            spr.offset.y=20;
            icon.offset.y=10;
            
            break;
            
        }                    
    }
    
}
game.insert(1,preview);

var rawText = Paths.getTextFromFile("data/freeplayImages.txt");
trace(rawText);
var display = {};
display.categories=[];

function loadTextToDisplay(rawText:Str){
    var rawArr = rawText.split("\n");
    for(o in rawArr){
        var temp = o.split(":");
        var values = temp[1].split(", ");
        for(value in values){
            Reflect.setProperty(display,value,temp[0]);
        }
        display.categories.push(temp[0]);
    }

}
loadTextToDisplay(rawText);

import("Math");
GameStages.set("changeSelection",{func:function(?curSelected:Int, ?playSound:Bool)
{
    if(curSelected==null) return;
    //trace(curSelected);
    
    var i:Int = 0;        
    for(spr in game.grpSongs.members)
    {
        spr.distancePerItem.x=0;
        var icon = iconMap.get(spr);
        if(i<=curSelected){
            spr.distancePerItem.x=-200*Math.sin((curSelected-i+7) * Math.PI/200);
        }
        if(i>=curSelected){
            spr.distancePerItem.x=200*Math.sin((i-curSelected+7) * Math.PI/200);
        }
        if(i==curSelected){
            curAlphabet=spr;
            icon.animation.play("active");
            trace(spr.text);
            preview.animation.play(Reflect.getProperty(display,spr.text));
        }
        else{
            icon.animation.play("inactive");
        }
        i++;
    }
}
});

GameStages.set("changeDiff",{func:function(?curDiff:Int)
{
    //trace(curDiff);
}
});

