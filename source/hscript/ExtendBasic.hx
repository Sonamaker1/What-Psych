package hscript;
import flixel.FlxBasic;

class ExtendBasic extends FlxBasic
{
    public var classType:Dynamic; //The actual type to extend

    public var superFields:Array<Dynamic>;      //This is going to be a pain lol
    public var superFieldNames:Array<String>; 

    public function new(TypeThing:Dynamic){
        super();

        classType = TypeThing;

        for(val in Reflect.fields(TypeThing)){
            trace(val);
        }
    }

}
