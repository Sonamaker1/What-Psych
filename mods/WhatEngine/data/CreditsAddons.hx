//FlxG.autoPause=false;
//trace("its working");

//trace(game.members);

//game.members[0].loadGraphic(Paths.image('mockup'));
game.members[0].alpha=0.6;
var u = (FlxG.width+10)/game.members[0].width;
game.members[0].scale.set(u,u);
game.members[0].updateHitbox();
game.members.remove(game.descBox);
game.insert(2,game.descBox);
game.descBox.x=700;
game.descBox.y=50;
  
funk.makeLuaSprite('white','', -1, -1);
funk.makeGraphic('white',2,2,'0xFFFFFFFF');
funk.scaleObject("white", FlxG.width+1, FlxG.height+1);
game.insert(0,game.modchartSprites.get("white"));

funk.makeLuaSprite('highlight','', -1, -1);
funk.makeGraphic('highlight',2,2,'0xFFFFFFFF');
funk.scaleObject("highlight", FlxG.width/4, 30);
var highlight =game.modchartSprites.get("highlight");
highlight.screenCenter(FlxAxes.Y);
highlight.y+=20;
highlight.x=20;
highlight.alpha=0.5;
game.insert(2,highlight);


GameStages.set("update",{func:function(?elapsed:float)
{
    game.members[1].alpha=0.6;
    game.descBox.sprTracker=null;
    if(game.moveTween != null) game.moveTween.cancel();
    game.descText.scrollFactor.set(0,0);
    game.descBox.x=750;
    game.descBox.y=50;
    game.descBox.setGraphicSize(Std.int(350 + 70), Std.int(550 + 25));
    game.descBox.updateHitbox();
    game.descText.width= 50;
    game.descText.height= 150;
    game.descText.setFormat(Paths.font("vcr.ttf"), 25, 0xFFFFFFFF, FlxAxes.CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
    game.descText.x=375;
    game.descText.y=235;
    game.descText.updateHitbox();
    
    //Reset Screen (for testing)
    if(FlxG.keys.justPressed.R){
        MusicBeatState.switchState(new CreditsState());
    }
}});


var sectionTexts:Array<String>=[];
for(icon in game.iconArray){
    for(spr in game.grpOptions.members)
    {
        if(spr.bold){
            spr.visible=false;
        }
        spr.distancePerItem.y=40;
        spr.scaleWord = 0.6;
           
        //spr.changeY = false;
        if(icon!=null && icon.sprTracker == spr){
            iconMap.set(spr, icon);
            break;
        }
        
                    
    }
    
}
function fixText(str:String, charLimit:Int){
    if(str==null)return null;
    var u = str.split("\n").join(" ").split(" ");
    
    var adder:Array<String>=[];
    var buffer:Array<String>=[];
    var bufferLength=0;
    for(str3 in u){
        if(str3.length>=charLimit){
            adder.push(str3);
        }
        else{
            if(bufferLength>=charLimit){
                adder.push(buffer.join(" "));
                buffer = [];
                bufferLength=0;
            }
            buffer.push(str3);
            bufferLength+=str3.length;
        }
    }

    if(bufferLength>0){
        adder.push(buffer.join(" "));
        buffer = [];
        bufferLength=0;
    }
    //var t:Array<String> =str.split("\n");
    //trace(t.join(" "));
    return adder.join("\n");
}

var oArr:Array<Int>=[];
var inc:Int=-1;
var i=0;
for(spr in game.grpOptions.members)
{
    if(spr.visible){
        spr.bold=true;    
        oArr.push(inc);
        //trace(game.creditsStuff[i][2]);
        var text = game.creditsStuff[i][2];
        game.creditsStuff[i][2] = fixText(text, 15);
        //trace(game.creditsStuff[i][2]);
        
    }
    spr.x = 400;   
    if(!spr.visible){
        if(spr.text.length>1){
            sectionTexts.push(spr.text);
            inc++;
            oArr.push(inc);
        }
        else
        {
            oArr.push(inc);
        }
        spr.visible=true; 
        spr.x = 400;   
        spr.offset.y=-25;
    }
    i++;
    //spr.offset.y+=10;
}

for(icon in game.iconArray){
    icon.sprTracker=null;
    icon.x=-1000;
}

var lastNumber:Int=0;

function abs(a:Int):Int{
    if(a<0) return a * -1;
    return a;
}

function sign(a:Int):Int{
    if(a<0) return -1;
    return 1;
}

var categoryText = new FlxText(775, 25, 1180, game.grpOptions.members[0].text, 32);
categoryText.setFormat(Paths.font("vcr.ttf"), 32, 0xFF000000, FlxAxes.LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
game.add(categoryText);

var nameText = new FlxText(775, 65, 1180, "Sample Name", 32);
nameText.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, FlxAxes.LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
game.add(nameText);


var caret = new FlxText(120, 25, 1180, ">", 32);
caret.setFormat(Paths.font("vcr.ttf"), 32, 0xFF000000, FlxAxes.LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
caret.screenCenter(FlxAxes.Y);
caret.y+=20;
game.add(caret);



var sectionNo=0;
function changeSectionName(change:Int, ?force:Bool){
    sectionNo=force?mod(change,sectionTexts.length):mod(sectionNo+change,sectionTexts.length);
    categoryText.text = sectionTexts[sectionNo];
    //trace(sectionTexts);
}
function mod(a:Int, b:Int) {
    var r:Int = a % b;
    return r < 0 ? r + b : r;
}
game.changeSelection();

GameStages.set("changeSelection",{func:function(?curSelected:Int)
    {
        //trace(curSelected);
        if(curSelected==null) {
            curSelected = 1;
            lastNumber = 1;
        }
        
        var diff:Int =curSelected-lastNumber;
        //trace(diff);
        if(abs(diff)>1){
            /*if(abs(diff)>=game.grpOptions.members.length-2){
                
                changeSectionName(diff>0?sectionTexts.length-1:0, true);
            }
            else{
                //trace("section jump "+sign(diff));
                changeSectionName(sign(diff));
            }*/
            changeSectionName(oArr[curSelected],true);
        }
        lastNumber=curSelected;

        for(icon in game.iconArray){
            icon.sprTracker=null;
            icon.x=-1000;
        }

        if(curSelected!=null){
            var i:Int = 0;
            
            for(spr in game.grpOptions.members)
            {
                var icon = iconMap.get(spr);
                if(i==curSelected){
                    //trace(icon);
                    icon.x=game.descBox.x+60+icon.width/2;
                    icon.y=game.descBox.y+10;
                    nameText.text = spr.text;//caret.y=spr.members[0].y;
                }
                i++;
            }
        }
    }
    });