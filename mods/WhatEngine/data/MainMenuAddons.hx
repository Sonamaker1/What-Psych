

trace("brand new bag");
game.members[0].loadGraphic(Paths.image('sunOil'));
var u:Int =FlxG.width*1.3;
var p:Int =FlxG.height*1.3;
game.members[0].setGraphicSize(u,p);
game.members[0].setPosition((u-1920),(p-1080)-80);

game.members[0].alpha = 1;
//game.members[0].color=0xFF512929;
//I took this from freestockfootagearchive.com lmao:
funk.makeAnimatedLuaSprite('NewBG', 'frames', -FlxG.width*0.2, -FlxG.height*0.2);
funk.addAnimationByPrefix('NewBG', 'loop', 'thumb', 12, true);
funk.scaleObject("NewBG",2, 2);
funk.setScrollFactor("NewBG",0, 0);

funk.makeLuaSprite('bgOverlay','curveThing', -100, -200);
funk.setScrollFactor("bgOverlay",0, game.members[0].scrollFactor.y*2);
//funk.makeGraphic('bgOverlay',2,2,'0xFF000000');
//funk.scaleObject("bgOverlay", FlxG.width/3+1, FlxG.height+1);

var bgover= game.modchartSprites.get("bgOverlay");
//bgover.scrollFactor.set(0,0);
bgover.alpha=0.6;
//bgover.angle =-30;
bgover.antialiasing=true;
bgover.color = 0xFF8D1E1E;

var bg = game.modchartSprites.get("NewBG");
bg.color = 0xFFDDDDDD;
bg.flipX = true;
game.insert(1,bgover);
//game.insert(0,bg);



var i:Int = 0;
game.menuItems.forEach(function(spr:FlxSprite)
{
    spr.x = 50;
    spr.angle =15+(-spr.ID+1)*8;
    //spr.y = 150*i;
    spr.scale.set(0.7,0.7);
    i++;
    spr.updateHitbox();
});


funk.makeAnimatedLuaSprite('boy', 'characters/BOYFRIEND', 900, p-300);
funk.addAnimationByPrefix('boy', 'idle', 'BF idle dance', 24, true);
funk.playAnim('boy', 'idle');
funk.scaleObject("boy",0.3,0.3);
funk.addLuaSprite("boy",true);
var getBF = game.modchartSprites.get("boy");
getBF.scrollFactor.set(0,game.members[0].scrollFactor.y*2);

GameStages.set("changeItem",{func:function(curSelected:Int)
{
    var i:Int = 0;
    game.menuItems.forEach(function(spr:FlxSprite)
    {
        if(spr.ID==curSelected){
            spr.x = spr.width*0.2+50;
            if(spr.ID==2){
                spr.x-=20;
            }    
            game.camFollow.setPosition(spr.x, spr.y);
            
        }else{
            spr.x = 50;
           
        }
        //spr.angle= 15+(curSelected-spr.ID)*8;
       
    });

}
});


GameStages.set("update",{func:function(?elapsed:float)
{  
    //Reset Screen (for testing)
    if(FlxG.keys.justPressed.R){
        MusicBeatState.switchState(new MainMenuState());
    }
}});


var cameraFollowPointer = new FlxSprite();
trace(cameraFollowPointer);
cameraFollowPointer.loadGraphic(Paths.image('cursor'));
//cameraFollowPointer.loadGraphic(pointer);
cameraFollowPointer.setGraphicSize(0, 40);
cameraFollowPointer.updateHitbox();
cameraFollowPointer.color = 0xFFFFFFFF;
//game.add(cameraFollowPointer);

import("CustomBeatState");


import("ClickableSprite");
var mover:FlxSprite = new ClickableSprite('credits/icon-whatify');
mover.scrollFactor.set(cameraFollowPointer.scrollFactor.x,cameraFollowPointer.scrollFactor.y);

function clickAndDrag(sprite:ClickableSprite, pos:Dynamic){
    sprite.setPosition(pos.x - sprite.width / 2, pos.y - sprite.height / 2);
}

GameStages.set("update",{func:function(elapsed:Float)
{
    cameraFollowPointer.setPosition(FlxG.mouse.getPosition().x-2, FlxG.mouse.getPosition().y-2);
           
    if(mover.clicked){
        clickAndDrag(mover,FlxG.mouse.getPosition());
    }
    if(game.members.indexOf(cameraFollowPointer)>game.members.length-1){
        game.remove(cameraFollowPointer);
        game.insert(game.members.length,cameraFollowPointer);
    }
    
    //Refresh page to test
    if(FlxG.keys.justPressed.R){
        MusicBeatState.switchState(new MainMenuState());
    }
    
}
});


//callSpriteFunctions("clicked",[this, FlxG.mouse.getPosition()],functs);
trace(mover.functs);
//mover.functs.set("clicked",{func:clickAndDrag});
//mover.loadGraphic(Paths.image(''));
//mover.setPosition(200,200);
game.add(mover);
game.add(cameraFollowPointer);



/*
var Label = "Stage Editor";

var t:FlxUIButton = new FlxUIButton(200, 200, Label);
t.broadcastToFlxUI = false;
//t.onUp.callback = onClickItem.bind(i);
t.name = "StageState";

t.loadGraphicSlice9([FlxUIAssets.IMG_INVIS, FlxUIAssets.IMG_HILIGHT, FlxUIAssets.IMG_HILIGHT], Std.int(300),
    Std.int(100), [[1, 1, 3, 3], [1, 1, 3, 3], [1, 1, 3, 3]], FlxUI9SliceSprite.TILE_NONE);
*/


