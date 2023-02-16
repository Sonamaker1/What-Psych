package;

import flixel.addons.ui.FlxUIState;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import ModchartTween;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.util.FlxAxes;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxTextNew as FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;
import MusicBeatState.ModchartSprite;
import MusicBeatState.ModchartText;
import MusicBeatState.BeatStateInterface;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

import Type.ValueType;
using StringTools;

class PlayState extends MusicBeatState
{

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var gameParameters:Map<String,Dynamic> = new Map<String,Dynamic>();
	public static var funk:FunkinUtil;
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	//public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;


	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();
	
	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public function setArrowSkinFromName(songName:String):Void
	{
		var noPlayerSkin = SONG.arrowSkin == null || SONG.arrowSkin.length < 1;
		var noOpponentSkin = SONG.opponentArrowSkin == null || SONG.opponentArrowSkin.length < 1;
		
		if(noPlayerSkin || noOpponentSkin){
			//W: I'll do this later but I'm adding this function for completion
			/*songName = songName.toLowerCase();
			switch (songName)
			{
				default: 
					if(noPlayerSkin) PlayState.SONG.arrowSkin = 'note_assets';
					if(noOpponentSkin) PlayState.SONG.opponentArrowSkin = "note_assets";
			}
			*/	
			//W: TO-DO, Add some hscript callback here lol.
		}
	}

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		funk = new FunkinUtil(instance, true);
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		songName = songName.toLowerCase();
		
		setArrowSkinFromName(songName);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				dadbattleSmokes = new FlxSpriteGroup(); //troll'd
			}

		//Game Over Substate stuff here
		/*switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}
		*/

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights
		add(dadGroup);
		add(boyfriendGroup);

		switch(curStage)
		{
			default:
				//callStageFunctions("foregroundAdd", []);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			//If no GF listed use 'gf' by default
			stageData.hide_girlfriend =  true;
			/*switch (curStage)
			{
				default:
					
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}*/
			SONG.gfVersion = 'gf'; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		//W, TODO: fast cars and flxTrails go here

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition; //W: GUH??? what is this?

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		//W: TODO Mechanics and shaders here? IDK LMAO
		/*switch (daSong){}*/
	
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		//W: I don't know if this is still used but it seems important? 
		//   Oh I see it was moved down to set playback rate lmao
		//Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
	}

	#if (!flash && sys)
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	override public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	//Removed intro function stuff lol

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;


			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				/*if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}*/

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = 'Score: ' + songScore
		+ ' | Misses: ' + songMisses
		+ ' | Rating: ' + ratingName
		+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		
		//Removed tank tower dance stuff

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	var vocalsFinished:Bool = false;
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();
		
		vocals.onComplete = function()
		{
			vocalsFinished = true;
		}

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				if(gottaHitNote){
					swagNote.isOppNote = daNoteData > 3;
				}else{
					swagNote.isOppNote = daNoteData < 4;
				}
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						if(gottaHitNote){
							sustainNote.isOppNote = daNoteData > 3;
						}else{
							sustainNote.isOppNote = daNoteData < 4;
						}
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);
			//Philly Glow? what's that?
			//There's nothing here about Philly Glow 
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}
		
		/* W, TODO: ADD THIS BACK IN SOME FORM WITH AN EVENT OFFSET OPTION MAYBE
		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}*/

		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player, -1);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			//if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			//if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		
		if (vocalsFinished)
			return;

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public static var maxLuaFPS = 60;
	var fpsElapsed:Array<Float> = [0,0,0];
	var numCalls:Array<Float> = [0,0,0];

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		// Limits the number of lua updates to 60/second, which fixes some crashes if FPS > 120
		// on long songs with multiple scripts that use onUpdate() function

		if(ClientPrefs.framerate <= maxLuaFPS){
			
			callOnLuas('onUpdate', [elapsed]);
		}
		else {
			numCalls[0]+=1;
			fpsElapsed[0]+=elapsed;
			if(numCalls[0] >= Std.int(ClientPrefs.framerate/maxLuaFPS)){
				//trace("New Update");
				callOnLuas('onUpdate', [fpsElapsed[0]]);
				fpsElapsed[0]=0;
				numCalls[0]=0;

			}
		}

		//W: TODO update codes based on the current stage
		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		
		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}

			if(startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;

					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					if (strumScroll) //Downscroll
					{
						//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}
					else //Upscroll
					{
						//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if(daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if(daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if(daNote.copyY)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if(strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
								} else {
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}

					if(!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit) {
						if(daNote.isSustainNote) {
							if(daNote.canBeHit) {
								goodNoteHit(daNote);
							}
						} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
							goodNoteHit(daNote);
						}
					}

					var center:Float = strumY + Note.swagWidth / 2;
					if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end
		//W: hscript camera system options here I guess?

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		
		//Fix for high fps lua crashes
		if(ClientPrefs.framerate <= maxLuaFPS){
			callOnLuas('onUpdatePost', [elapsed]);
		}
		else {
			numCalls[1]+=1;
			fpsElapsed[1]+=elapsed;
			if(numCalls[1] >= Std.int(ClientPrefs.framerate/maxLuaFPS)){
				//trace("New UpdatePost");
				callOnLuas('onUpdatePost', [fpsElapsed[1]]);
				fpsElapsed[1]=0;
				numCalls[1]=0;
			}
		}
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else {*/
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					/*if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}*/
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			//Philly Glow more like Philly No am i right? jk I'm moving it to hscript later
	

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}
	


	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			moveCamera(true, 1);
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, ?isGF:Int = 0)
	{
		//W: TODO, add the ability to disable camera movements per character
		if(isGF > 0){
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
		}
		else if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
		
		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else{
					callOnLuas('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				//W: TODO add some opponent camera follow callback stuff here maybe
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					//W: TODO add some player camera follow callback stuff here maybe
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			} else {
				var spr = playerStrums.members[note.noteData];
				if(spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[data][0] / 360;
			sat = ClientPrefs.arrowHSV[data][1] / 100;
			brt = ClientPrefs.arrowHSV[data][2] / 100;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (!vocalsFinished && SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}


	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}
		//Beat Hit stage specific
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}


	

	override public function callOnLuas(event:String, args:Array<Dynamic>, ?ignoreStops = true, ?exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end

		//callStageFunctions(event,args);
		

		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ !ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}


/*
typedef GameplayOptions =
{
	@:optional var foregroundAdd:FunkyFunct; 
	@:optional var onEndSong:FunkyFunct; 
	@:optional var onGameOver:FunkyFunct; 
	@:optional var onPause:FunkyFunct; 
	@:optional var onRecalculateRating:FunkyFunct; 
	@:optional var onStartCountdown:FunkyFunct; 
	@:optional var goodNoteHit:FunkyFunct; 
	@:optional var noteMiss:FunkyFunct; 
	@:optional var noteMissPress:FunkyFunct; 
	@:optional var onBeatHit:FunkyFunct; 
	@:optional var onCountdownStarted:FunkyFunct; 
	@:optional var onCountdownTick:FunkyFunct; 
	@:optional var onCreatePost:FunkyFunct; 
	@:optional var onEvent:FunkyFunct; 
	@:optional var onGhostTap:FunkyFunct; 
	@:optional var onKeyPress:FunkyFunct; 
	@:optional var onKeyRelease:FunkyFunct; 
	@:optional var onMoveCamera:FunkyFunct; 
	@:optional var onNextDialogue:FunkyFunct; 
	@:optional var onResume:FunkyFunct; 
	@:optional var onSectionHit:FunkyFunct; 
	@:optional var onSkipDialogue:FunkyFunct; 
	@:optional var onSongStart:FunkyFunct; 
	@:optional var onSpawnNote:FunkyFunct; 
	@:optional var onStepHit:FunkyFunct; 
	@:optional var onUpdate:FunkyFunct; 
	@:optional var onUpdatePost:FunkyFunct; 
	@:optional var onUpdateScore:FunkyFunct; 
	@:optional var opponentNoteHit:FunkyFunct; 
	@:optional var eventEarlyTrigger:FunkyFunct; 
}
*/

class FunkinUtil  {

	public static var utilInstance:BeatStateInterface;
	
	public static function utilInst():BeatStateInterface{
		if(subInstance!=null){
			return cast(subInstance,MusicBeatSubstate);
		}
		else{
			return cast(utilInstance,MusicBeatState);
		}
	}

	public static function utilInstGet(str:String):Dynamic{
		var ret:Dynamic ="undefined";
		var a:MusicBeatState=null;
		var b:MusicBeatSubstate=null;
		if(!isSubstate){
			a = cast(utilInstance,MusicBeatState);
		}
		else{
			b = cast(subInstance,MusicBeatSubstate);
		}

		switch(str){
			case       "variables": ret = (isSubstate&&b!=null)?b.variables:a.variables; 
			case  "modchartTweens": ret = (isSubstate&&b!=null)?b.modchartTweens:a.modchartTweens; 
			case "modchartSprites": ret = (isSubstate&&b!=null)?b.modchartSprites:a.modchartSprites; 
			case  "modchartTimers": ret = (isSubstate&&b!=null)?b.modchartTimers:a.modchartTimers; 
			case  "modchartSounds": ret = (isSubstate&&b!=null)?b.modchartSounds:a.modchartSounds; 
			case   "modchartTexts": ret = (isSubstate&&b!=null)?b.modchartTexts:a.modchartTexts; 
			case   "modchartSaves": ret = (isSubstate&&b!=null)?b.modchartSaves:a.modchartSaves; 
		}
		return ret;
	}

	public static function getMembers():Array<flixel.FlxBasic>{
		if(subInstance!=null){
			return cast(subInstance,MusicBeatSubstate).members;
		}
		else{
			return cast(utilInstance,MusicBeatState).members;
		}
	}

	
	public static var subInstance:MusicBeatSubstate;
	public static var playInstance:PlayState;
	public static var isPlayState:Bool;
	public static var isSubstate:Bool;

	public function new(inputInstance:Dynamic, ?isPlay:Bool = false, ?isSubs:Bool=false){
		isSubstate=isSubs;
		if(!isSubstate){
			utilInstance = cast(inputInstance,BeatStateInterface);
			if(isPlay){
				playInstance = cast(inputInstance, PlayState);
				isPlayState = isPlay;
			}
			subInstance = null;
		}
		else{
			subInstance = cast(inputInstance,MusicBeatSubstate);
			utilInstance = cast(subInstance,BeatStateInterface);
		}
	}

    public static function getInstance():FlxState
    {
		if(!isSubstate){
			var dead:Bool = false;
			try{
				var obj:Dynamic = Reflect.getProperty(utilInst(), "isDead");
				if(obj != null){
					dead = obj;
				}
			}
			catch(err){
				dead = false;
			}
			return dead ? cast(GameOverSubstate.instance, FlxState) : cast(utilInst(), FlxState);
		}else{
			return cast(utilInst(), FlxSubState);
		}
    }
    
    public function funkyTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
        if(isPlayState) playInstance.addTextToDebug(text, color);
        trace(text);
    }

    
    public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
    {
        var shit:Array<String> = variable.split('[');
        if(shit.length > 1)
        {
            var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
            for (i in 1...shit.length)
            {
                var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
                if(i >= shit.length-1) //Last array
                    blah[leNum] = value;
                else //Anything else
                    blah = blah[leNum];
            }
            return blah;
        }
        /*if(Std.isOfType(instance, Map))
            instance.set(variable,value);
        else*/

        Reflect.setProperty(instance, variable, value);
        return true;
    }
    public static function getVarInArray(instance:Dynamic, variable:String):Any
    {
        var shit:Array<String> = variable.split('[');
        if(shit.length > 1)
        {
            var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
            for (i in 1...shit.length)
            {
                var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
                blah = blah[leNum];
            }
            return blah;
        }

        return Reflect.getProperty(instance, variable);
    }

    inline static function getTextObject(name:String):FlxText
    {
        return utilInstGet("modchartTexts").exists(name) ? utilInstGet("modchartTexts").get(name) : Reflect.getProperty(PlayState.instance, name);
    }

    public function getShader(obj:String):FlxRuntimeShader
    {
        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            var shader:Dynamic = leObj.shader;
            var shader:FlxRuntimeShader = shader;
            return shader;
        }
        return null;
    }
    
    function initLuaShaderHelper(name:String, ?glslVersion:Int = 120)
    {
        if(!ClientPrefs.shaders) return false;

        if(utilInstGet("runtimeShaders").exists(name))
        {
            funkyTrace('Shader $name was already initialized!');
            return true;
        }

        var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
        if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
            foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

        for(mod in Paths.getGlobalMods())
            foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
        
        for (folder in foldersToCheck)
        {
            if(FileSystem.exists(folder))
            {
                var frag:String = folder + name + '.frag';
                var vert:String = folder + name + '.vert';
                var found:Bool = false;
                if(FileSystem.exists(frag))
                {
                    frag = File.getContent(frag);
                    found = true;
                }
                else frag = null;

                if (FileSystem.exists(vert))
                {
                    vert = File.getContent(vert);
                    found = true;
                }
                else vert = null;

                if(found)
                {
                    utilInstGet("runtimeShaders").set(name, [frag, vert]);
                    //trace('Found shader $name!');
                    return true;
                }
            }
        }
        funkyTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
        return false;
    }

    function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch(Type.typeof(coverMeInPiss)){
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length-1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			};
		}
		switch(Type.typeof(leArray)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		};
	}

	function loadFramesHelper(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);

			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	function resetTextTag(tag:String) {
		if(!utilInstGet("modchartTexts").exists(tag)) {
			return;
		}

		var pee:ModchartText = utilInstGet("modchartTexts").get(tag);
		pee.kill();
		if(pee.wasAdded) {
			if(!isSubstate){
				cast(utilInst(),MusicBeatState).remove(pee, true);
			}else{
				cast(utilInst(),MusicBeatSubstate).remove(pee, true);
			}
		}
		pee.destroy();
		utilInstGet("modchartTexts").remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if(!utilInstGet("modchartSprites").exists(tag)) {
			return;
		}

		var pee:ModchartSprite = utilInstGet("modchartSprites").get(tag);
		pee.kill();
		if(pee.wasAdded) {
			if(!isSubstate){
				cast(utilInst(),MusicBeatState).remove(pee, true);
			}else{
				cast(utilInst(),MusicBeatSubstate).remove(pee, true);
			}
		}
		pee.destroy();
		utilInstGet("modchartSprites").remove(tag);
	}

	function cancelTween(tag:String) {
		if(utilInstGet("modchartTweens").exists(tag)) {
			utilInstGet("modchartTweens").get(tag).cancel();
			utilInstGet("modchartTweens").get(tag).destroy();
			utilInstGet("modchartTweens").remove(tag);
		}
	}

	function tweenShit(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) {
			sexyProp = getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length-1]);
		}
		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if(utilInstGet("modchartTimers").exists(tag)) {
			var theTimer:FlxTimer = utilInstGet("modchartTimers").get(tag);
			theTimer.cancel();
			theTimer.destroy();
			utilInstGet("modchartTimers").remove(tag);
		}
	}

	//Better optimized than using some getProperty shit or idk
	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	function cameraFromString(cam:String):FlxCamera {
		if(isPlayState){
			switch(cam.toLowerCase()) {
				case 'camhud' | 'hud': return playInstance.camHUD;
				case 'camother' | 'other': return playInstance.camOther;
			}
			return playInstance.camGame;
		}
		else{
			return utilInst().camGame;
		}
	}

    static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
    {
        var strIndices:Array<String> = indices.trim().split(',');
        var die:Array<Int> = [];
        for (i in 0...strIndices.length) {
            die.push(Std.parseInt(strIndices[i]));
        }

        if(utilInst().getLuaObject(obj, false)!=null) {
            var pussy:FlxSprite = utilInst().getLuaObject(obj, false);
            pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
            return true;
        }

        var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(pussy != null) {
            pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
            return true;
        }
        return false;
    }

    public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
    {
        var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
        var end = killMe.length;
        if(getProperty)end=killMe.length-1;

        for (i in 1...end) {
            coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
        }
        return coverMeInPiss;
    }

    public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
    {
        var coverMeInPiss:Dynamic = utilInst().getLuaObject(objectName, checkForTextsToo);
        if(coverMeInPiss==null)
            coverMeInPiss = getVarInArray(getInstance(), objectName);

        return coverMeInPiss;
    }

    /*
    // Lua shit
    set('Function_StopLua', Function_StopLua);
    set('Function_Stop', Function_Stop);
    set('Function_Continue', Function_Continue);
    set('luaDebugMode', false);
    set('luaDeprecatedWarnings', true);
    set('inChartEditor', false);

    // Song/Week shit
    set('curBpm', Conductor.bpm);
    set('bpm', PlayState.SONG.bpm);
    set('scrollSpeed', PlayState.SONG.speed);
    set('crochet', Conductor.crochet);
    set('stepCrochet', Conductor.stepCrochet);
    set('songLength', FlxG.sound.music.length);
    set('songName', PlayState.SONG.song);
    set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
    set('startedCountdown', false);

    set('isStoryMode', PlayState.isStoryMode);
    set('difficulty', PlayState.storyDifficulty);

    var difficultyName:String = CoolUtil.difficulties[PlayState.storyDifficulty];
    set('difficultyName', difficultyName);
    set('difficultyPath', Paths.formatToSongPath(difficultyName));
    set('weekRaw', PlayState.storyWeek);
    set('week', WeekData.weeksList[PlayState.storyWeek]);
    set('seenCutscene', PlayState.seenCutscene);

    // Camera poo
    set('cameraX', 0);
    set('cameraY', 0);

    // Screen stuff
    set('screenWidth', FlxG.width);
    set('screenHeight', FlxG.height);

    // PlayState cringe ass nae nae bullcrap
    set('curBeat', 0);
    set('curStep', 0);
    set('curDecBeat', 0);
    set('curDecStep', 0);

    set('score', 0);
    set('misses', 0);
    set('hits', 0);

    set('rating', 0);
    set('ratingName', '');
    set('ratingFC', '');
    set('version', MainMenuState.psychEngineVersion.trim());

    set('inGameOver', false);
    set('mustHitSection', false);
    set('altAnim', false);
    set('gfSection', false);

    // Gameplay settings
    set('healthGainMult', utilInst().healthGain);
    set('healthLossMult', utilInst().healthLoss);
    set('instakillOnMiss', utilInst().instakillOnMiss);
    set('botPlay', utilInst().cpuControlled);
    set('practice', utilInst().practiceMode);

    for (i in 0...4) {
        set('defaultPlayerStrumX' + i, 0);
        set('defaultPlayerStrumY' + i, 0);
        set('defaultOpponentStrumX' + i, 0);
        set('defaultOpponentStrumY' + i, 0);
    }

    // Default character positions woooo
    set('defaultBoyfriendX', utilInst().BF_X);
    set('defaultBoyfriendY', utilInst().BF_Y);
    set('defaultOpponentX', utilInst().DAD_X);
    set('defaultOpponentY', utilInst().DAD_Y);
    set('defaultGirlfriendX', utilInst().GF_X);
    set('defaultGirlfriendY', utilInst().GF_Y);

    // Character shit
    set('boyfriendName', PlayState.SONG.player1);
    set('dadName', PlayState.SONG.player2);
    set('gfName', PlayState.SONG.gfVersion);

    // Some settings, no jokes
    set('downscroll', ClientPrefs.downScroll);
    set('middlescroll', ClientPrefs.middleScroll);
    set('framerate', ClientPrefs.framerate);
    set('ghostTapping', ClientPrefs.ghostTapping);
    set('hideHud', ClientPrefs.hideHud);
    set('timeBarType', ClientPrefs.timeBarType);
    set('scoreZoom', ClientPrefs.scoreZoom);
    set('cameraZoomOnBeat', ClientPrefs.camZooms);
    set('flashingLights', ClientPrefs.flashing);
    set('noteOffset', ClientPrefs.noteOffset);
    set('healthBarAlpha', ClientPrefs.healthBarAlpha);
    set('noResetButton', ClientPrefs.noReset);
    set('lowQuality', ClientPrefs.lowQuality);
    set('shadersEnabled', ClientPrefs.shaders);
    set('scriptName', scriptName);
    set('currentModDirectory', Paths.currentModDirectory);

    #if windows
    set('buildTarget', 'windows');
    #elseif linux
    set('buildTarget', 'linux');
    #elseif mac
    set('buildTarget', 'mac');
    #elseif html5
    set('buildTarget', 'browser');
    #elseif android
    set('buildTarget', 'android');
    #else
    set('buildTarget', 'unknown');
    #end

    */
    //public function onCreate(){
    
    // shader shit
    public function initLuaShader(name:String, glslVersion:Int = 120) {
        if(!ClientPrefs.shaders) return false;

        #if (!flash && MODS_ALLOWED && sys)
        return initLuaShaderHelper(name, glslVersion);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
    }
    
    public function setSpriteShader(obj:String, shader:String) {
        if(!ClientPrefs.shaders) return false;

        #if (!flash && MODS_ALLOWED && sys)
        if(!utilInstGet("runtimeShaders").exists(shader) && !initLuaShaderHelper(shader))
        {
            funkyTrace('Shader $shader is missing!', false, false, FlxColor.RED);
            return false;
        }

        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            var arr:Array<String> = utilInstGet("runtimeShaders").get(shader);
            leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
            return true;
        }
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
    }
    public function removeSpriteShader(obj:String) {
        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            leObj.shader = null;
            return true;
        }
        return false;
    }


    public function getShaderBool(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getBool(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderBoolArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getBoolArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderInt(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getInt(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderIntArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getIntArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderFloat(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getFloat(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderFloatArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getFloatArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }


    public function setShaderBool(obj:String, prop:String, value:Bool) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setBool(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderBoolArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setBoolArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderInt(obj:String, prop:String, value:Int) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setInt(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderIntArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setIntArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderFloat(obj:String, prop:String, value:Float) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setFloat(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderFloatArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setFloatArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }


    //

    /*
    public function runHaxeCode(codeToRun:String) {
        #if hscript
        initHaxeInterp();

        try {
            var myFunction:Dynamic = haxeInterp.expr(new Parser().parseString(codeToRun));
            myFunction();
        }
        catch (e:Dynamic) {
            switch(e)
            {
                case 'Null Function Pointer', 'SReturn':
                    //nothing
                default:
                    funkyTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
            }
        }
        #end
    }

    public function addHaxeLibrary(libName:String, ?libPackage:String = '') {
        #if hscript
        initHaxeInterp();

        try {
            var str:String = '';
            if(libPackage.length > 0)
                str = libPackage + '.';

            haxeInterp.variables.set(libName, Type.resolveClass(str + libName));
        }
        catch (e:Dynamic) {
            funkyTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
        }
        #end
    }
    */

	public function addHaxeLibrary(haxeInterpret:FunkinLua.HScript, libName:String, ?libPackage:String = '') {
        #if hscript
        var str:String = '';
        try {
            if(libPackage!=null && libPackage.length > 0)
                str = libPackage + '.';
			trace(Type.resolveClass(str + libName));
            haxeInterpret.interp.variables.set(libName, Type.resolveClass(str + libName));
        }
        catch (e:Dynamic) {
            funkyTrace(e+"\naddHaxeLibrary: failed to init [" + str+libName+"]");
        }
        #end
    }

    public function loadSong(?name:String = null, ?difficultyNum:Int = -1) {
        if(isPlayState){
			if(name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			playInstance.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(playInstance.vocals != null)
			{
				playInstance.vocals.pause();
				playInstance.vocals.volume = 0;
			}
		}
    }

    public function loadGraphic(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
        var killMe:Array<String> = variable.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        var gX = gridX==null?0:gridX;
        var gY = gridY==null?0:gridY;
        var animated = gX!=0 || gY!=0;

        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null && image != null && image.length > 0)
        {
            spr.loadGraphic(Paths.image(image), animated, gX, gY);
        }
    }
    public function loadFrames(variable:String, image:String, spriteType:String = "sparrow") {
        var killMe:Array<String> = variable.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null && image != null && image.length > 0)
        {
            loadFramesHelper(spr, image, spriteType);
        }
    }

    // gay ass tweens
    public function doTweenX(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstGet("modchartTweens").set(tag, FlxTween.tween(penisExam, {x: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                    utilInstGet("modchartTweens").remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenY(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstGet("modchartTweens").set(tag, FlxTween.tween(penisExam, {y: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                    utilInstGet("modchartTweens").remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenAngle(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstGet("modchartTweens").set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                    utilInstGet("modchartTweens").remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenAlpha(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstGet("modchartTweens").set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                    utilInstGet("modchartTweens").remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenZoom(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstGet("modchartTweens").set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                    utilInstGet("modchartTweens").remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenColor(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            var color:Int = Std.parseInt(targetColor);
            if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

            var curColor:FlxColor = penisExam.color;
            curColor.alphaFloat = penisExam.alpha;
            utilInstGet("modchartTweens").set(tag, FlxTween.color(penisExam, duration, curColor, color, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstGet("modchartTweens").remove(tag);
                    utilInst().callOnLuas('onTweenCompleted', [tag]);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }

    //Tween shit, but for strums
    public function noteTweenX(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function noteTweenY(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    
    public function noteTweenDirection(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function mouseClicked(button:String) {
        var boobs = FlxG.mouse.justPressed;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.justPressedMiddle;
            case 'right':
                boobs = FlxG.mouse.justPressedRight;
        }


        return boobs;
    }
    public function mousePressed(button:String) {
        var boobs = FlxG.mouse.pressed;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.pressedMiddle;
            case 'right':
                boobs = FlxG.mouse.pressedRight;
        }
        return boobs;
    }
    public function mouseReleased(button:String) {
        var boobs = FlxG.mouse.justReleased;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.justReleasedMiddle;
            case 'right':
                boobs = FlxG.mouse.justReleasedRight;
        }
        return boobs;
    }
    public function noteTweenAngle(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function noteTweenAlpha(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }


    public function runTimer(tag:String, time:Float = 1, loops:Int = 1) {
        cancelTimer(tag);
        utilInstGet("modchartTimers").set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
            if(tmr.finished) {
                utilInstGet("modchartTimers").remove(tag);
            }
            utilInstance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
            //trace('Timer Completed: ' + tag);
        }, loops));
    }
    

    /*public function getPropertyAdvanced(varsStr:String) {
        var variables:Array<String> = varsStr.replace(' ', '').split(',');
        var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
        if(variables.length > 2) {
            var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
            if(variables.length > 3) {
                for (i in 2...variables.length-1) {
                    curProp = Reflect.getProperty(curProp, variables[i]);
                }
            }
            return Reflect.getProperty(curProp, variables[variables.length-1]);
        } else if(variables.length == 2) {
            return Reflect.getProperty(leClass, variables[variables.length-1]);
        }
        return null;
    }
    public function setPropertyAdvanced(varsStr:String, value:Dynamic) {
        var variables:Array<String> = varsStr.replace(' ', '').split(',');
        var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
        if(variables.length > 2) {
            var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
            if(variables.length > 3) {
                for (i in 2...variables.length-1) {
                    curProp = Reflect.getProperty(curProp, variables[i]);
                }
            }
            return Reflect.setProperty(curProp, variables[variables.length-1], value);
        } else if(variables.length == 2) {
            return Reflect.setProperty(leClass, variables[variables.length-1], value);
        }
    }*/

    //stupid bietch ass functions
    public function addScore(value:Int = 0) {
		if(!isPlayState) return;
        playInstance.songScore += value;
        playInstance.RecalculateRating();
    }
    public function addMisses(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songMisses += value;
        playInstance.RecalculateRating();
    }
    public function addHits(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songHits += value;
        playInstance.RecalculateRating();
    }
    public function setScore(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songScore = value;
        playInstance.RecalculateRating();
    }
    public function setMisses(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songMisses = value;
        playInstance.RecalculateRating();
    }
    public function setHits(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songHits = value;
        playInstance.RecalculateRating();
    }
    public function getScore():Int {
        if(!isPlayState) return 0;
        return playInstance.songScore;
    }
    public function getMisses():Int {
        if(!isPlayState) return 0;
        return playInstance.songMisses;
    }
    public function getHits():Int {
        if(!isPlayState) return 0;
        return playInstance.songHits;
    }

    public function setHealth(value:Float = 0) {
        if(!isPlayState) return;
        playInstance.health = value;
    }
    public function addHealth(value:Float = 0) {
        if(!isPlayState) return;
        playInstance.health += value;
    }
    public function getHealth():Float {
        if(!isPlayState) return -1.0;
        return playInstance.health;
    }

    public function getColorFromHex(color:String) {
        if(!color.startsWith('0x')) color = '0xff' + color;
        return Std.parseInt(color);
    }

    public function keyboardJustPressed(name:String)
    {
        return Reflect.getProperty(FlxG.keys.justPressed, name);
    }
    public function keyboardPressed(name:String)
    {
        return Reflect.getProperty(FlxG.keys.pressed, name);
    }
    public function keyboardReleased(name:String)
    {
        return Reflect.getProperty(FlxG.keys.justReleased, name);
    }

    public function anyGamepadJustPressed(name:String)
    {
        return FlxG.gamepads.anyJustPressed(name);
    }
    public function anyGamepadPressed(name:String)
    {
        return FlxG.gamepads.anyPressed(name);
    }
    public function anyGamepadReleased(name:String)
    {
        return FlxG.gamepads.anyJustReleased(name);
    }

    public function gamepadAnalogX(id:Int, ?leftStick:Bool = true)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return 0.0;
        }
        return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    }
    public function gamepadAnalogY(id:Int, ?leftStick:Bool = true)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return 0.0;
        }
        return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    }
    public function gamepadJustPressed(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.justPressed, name) == true;
    }
    public function gamepadPressed(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.pressed, name) == true;
    }
    public function gamepadReleased(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.justReleased, name) == true;
    }

    public function keyJustPressed(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInst().getControl('NOTE_LEFT_P');
            case 'down': key = utilInst().getControl('NOTE_DOWN_P');
            case 'up': key = utilInst().getControl('NOTE_UP_P');
            case 'right': key = utilInst().getControl('NOTE_RIGHT_P');
            case 'accept': key = utilInst().getControl('ACCEPT');
            case 'back': key = utilInst().getControl('BACK');
            case 'pause': key = utilInst().getControl('PAUSE');
            case 'reset': key = utilInst().getControl('RESET');
            case 'space': key = FlxG.keys.justPressed.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function keyPressed(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInst().getControl('NOTE_LEFT');
            case 'down': key = utilInst().getControl('NOTE_DOWN');
            case 'up': key = utilInst().getControl('NOTE_UP');
            case 'right': key = utilInst().getControl('NOTE_RIGHT');
            case 'space': key = FlxG.keys.pressed.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function keyReleased(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInst().getControl('NOTE_LEFT_R');
            case 'down': key = utilInst().getControl('NOTE_DOWN_R');
            case 'up': key = utilInst().getControl('NOTE_UP_R');
            case 'right': key = utilInst().getControl('NOTE_RIGHT_R');
            case 'space': key = FlxG.keys.justReleased.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function addCharacterToList(name:String, type:String) {
        if(!isPlayState) return;
		var charType:Int = 0;
        switch(type.toLowerCase()) {
            case 'dad': charType = 1;
            case 'gf' | 'girlfriend': charType = 2;
        }
        playInstance.addCharacterToList(name, charType);
    }
    public function precacheImage(name:String) {
        Paths.returnGraphic(name);
    }
    public function precacheSound(name:String) {
        CoolUtil.precacheSound(name);
    }
    public function precacheMusic(name:String) {
        CoolUtil.precacheMusic(name);
    }
    public function triggerEvent(name:String, arg1:Dynamic, arg2:Dynamic) {
        if(!isPlayState) return true;
		var value1:String = arg1;
        var value2:String = arg2;
        playInstance.triggerEventNote(name, value1, value2);
        //trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
        return true;
    }

    public function startCountdown() {
        if(!isPlayState) return true;
		playInstance.startCountdown();
        return true;
    }
    public function endSong() {
        if(!isPlayState) return true;
		playInstance.KillNotes();
        playInstance.endSong();
        return true;
    }
    public function restartSong(?skipTransition:Bool = false) {
        utilInst().persistentUpdate = false;
        PauseSubState.restartSong(skipTransition);
        return true;
    }
    public function exitSong(?skipTransition:Bool = false) {
        if(!isPlayState) return true;
		if(skipTransition)
        {
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
        }

        PlayState.cancelMusicFadeTween();
        CustomFadeTransition.nextCamera = playInstance.camOther;
        if(FlxTransitionableState.skipNextTransIn)
            CustomFadeTransition.nextCamera = null;

        if(PlayState.isStoryMode)
            MusicBeatState.switchState(new StoryMenuState());
        else
            MusicBeatState.switchState(new FreeplayState());

        FlxG.sound.playMusic(Paths.music('freakyMenu'));
        PlayState.changedDifficulty = false;
        PlayState.chartingMode = false;
        playInstance.transitioning = true;
        WeekData.loadTheFirstEnabledMod();
        return true;
    }
    public function getSongPosition() {
        return Conductor.songPosition;
    }

    public function getCharacterX(type:String) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                return playInstance.dadGroup.x;
            case 'gf' | 'girlfriend':
                return playInstance.gfGroup.x;
            default:
                return playInstance.boyfriendGroup.x;
        }
    }
    public function setCharacterX(type:String, value:Float) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                playInstance.dadGroup.x = value;
            case 'gf' | 'girlfriend':
                playInstance.gfGroup.x = value;
            default:
                playInstance.boyfriendGroup.x = value;
        }
    }
    public function getCharacterY(type:String) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                return playInstance.dadGroup.y;
            case 'gf' | 'girlfriend':
                return playInstance.gfGroup.y;
            default:
                return playInstance.boyfriendGroup.y;
        }
    }
    public function setCharacterY(type:String, value:Float) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                playInstance.dadGroup.y = value;
            case 'gf' | 'girlfriend':
                playInstance.gfGroup.y = value;
            default:
                playInstance.boyfriendGroup.y = value;
        }
    }
    public function cameraSetTarget(target:String) {
        var isDad:Bool = false;
        if(target == 'dad') {
            isDad = true;
        }
        playInstance.moveCamera(isDad);
        return isDad;
    }
    public function cameraShake(camera:String, intensity:Float, duration:Float) {
        cameraFromString(camera).shake(intensity, duration);
    }

    public function cameraFlash(camera:String, color:String, duration:Float,forced:Bool) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
        cameraFromString(camera).flash(colorNum, duration,null,forced);
    }
    public function cameraFade(camera:String, color:String, duration:Float,forced:Bool) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
        cameraFromString(camera).fade(colorNum, duration,false,null,forced);
    }
    public function setRatingPercent(value:Float) {
        playInstance.ratingPercent = value;
    }
    public function setRatingName(value:String) {
        playInstance.ratingName = value;
    }
    public function setRatingFC(value:String) {
        playInstance.ratingFC = value;
    }
    public function getMouseX(camera:String) {
        var cam:FlxCamera = cameraFromString(camera);
        return FlxG.mouse.getScreenPosition(cam).x;
    }
    public function getMouseY(camera:String) {
        var cam:FlxCamera = cameraFromString(camera);
        return FlxG.mouse.getScreenPosition(cam).y;
    }

    public function getMidpointX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getMidpoint().x;

        return 0;
    }
    public function getMidpointY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getMidpoint().y;

        return 0;
    }
    public function getGraphicMidpointX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getGraphicMidpoint().x;

        return 0;
    }
    public function getGraphicMidpointY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getGraphicMidpoint().y;

        return 0;
    }
    public function getScreenPositionX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getScreenPosition().x;

        return 0;
    }
    public function getScreenPositionY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getScreenPosition().y;

        return 0;
    }
    public function characterDance(character:String) {
        if(!isPlayState) return;
		switch(character.toLowerCase()) {
            case 'dad': playInstance.dad.dance();
            case 'gf' | 'girlfriend': if(playInstance.gf != null) playInstance.gf.dance();
            default: playInstance.boyfriend.dance();
        }
    }

    public function makeLuaSprite(tag:String, image:String, x:Float, y:Float) {
        tag = tag.replace('.', '');
        resetSpriteTag(tag);
        var leSprite:ModchartSprite = new ModchartSprite(x, y);
        if(image != null && image.length > 0)
        {
            leSprite.loadGraphic(Paths.image(image));
        }
        leSprite.antialiasing = ClientPrefs.globalAntialiasing;
        utilInstGet("modchartSprites").set(tag, leSprite);
        leSprite.active = true;
    }
    public function makeAnimatedLuaSprite(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
        tag = tag.replace('.', '');
        resetSpriteTag(tag);
        var leSprite:ModchartSprite = new ModchartSprite(x, y);

        loadFramesHelper(leSprite, image, spriteType);
        leSprite.antialiasing = ClientPrefs.globalAntialiasing;
        utilInstGet("modchartSprites").set(tag, leSprite);
    }

    public function makeGraphic(obj:String, width:Int, height:Int, color:String) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

        var spr:FlxSprite = utilInst().getLuaObject(obj,false);
        if(spr!=null) {
            utilInst().getLuaObject(obj,false).makeGraphic(width, height, colorNum);
            return;
        }

        var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(object != null) {
            object.makeGraphic(width, height, colorNum);
        }
    }
    public function addAnimationByPrefix(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
        if(utilInst().getLuaObject(obj,false)!=null) {
            var cock:FlxSprite = utilInst().getLuaObject(obj,false);
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
            return;
        }

        var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(cock != null) {
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }

    public function addAnimation(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
        if(utilInst().getLuaObject(obj,false)!=null) {
            var cock:FlxSprite = utilInst().getLuaObject(obj,false);
            cock.animation.add(name, frames, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
            return;
        }

        var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(cock != null) {
            cock.animation.add(name, frames, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }

    public function addAnimationByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        return addAnimByIndices(obj, name, prefix, indices, framerate, false);
    }
    public function addAnimationByIndicesLoop(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        return addAnimByIndices(obj, name, prefix, indices, framerate, true);
    }
    

    public function playAnim(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
    {
        if(utilInst().getLuaObject(obj, false) != null) {
            var luaObj:FlxSprite = utilInst().getLuaObject(obj,false);
            if(luaObj.animation.getByName(name) != null)
            {
                luaObj.animation.play(name, forced, reverse, startFrame);
                if(Std.isOfType(luaObj, ModchartSprite))
                {
                    //convert luaObj to ModchartSprite
                    var obj:Dynamic = luaObj;
                    var luaObj:ModchartSprite = obj;

                    var daOffset = luaObj.animOffsets.get(name);
                    if (luaObj.animOffsets.exists(name))
                    {
                        luaObj.offset.set(daOffset[0], daOffset[1]);
                    }
                    else
                        luaObj.offset.set(0, 0);
                }
            }
            return true;
        }

        var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(spr != null) {
            if(spr.animation.getByName(name) != null)
            {
                if(Std.isOfType(spr, Character))
                {
                    //convert spr to Character
                    var obj:Dynamic = spr;
                    var spr:Character = obj;
                    spr.playAnim(name, forced, reverse, startFrame);
                }
                else
                    spr.animation.play(name, forced, reverse, startFrame);
            }
            return true;
        }
        return false;
    }
    public function addOffset(obj:String, anim:String, x:Float, y:Float) {
        if(utilInstGet("modchartSprites").exists(obj)) {
            utilInstGet("modchartSprites").get(obj).animOffsets.set(anim, [x, y]);
            return true;
        }

        var char:Character = Reflect.getProperty(getInstance(), obj);
        if(char != null) {
            char.addOffset(anim, x, y);
            return true;
        }
        return false;
    }

    public function setScrollFactor(obj:String, scrollX:Float, scrollY:Float) {
        if(utilInst().getLuaObject(obj,false)!=null) {
            utilInst().getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
            return;
        }

        var object:FlxObject = Reflect.getProperty(getInstance(), obj);
        if(object != null) {
            object.scrollFactor.set(scrollX, scrollY);
        }
    }
    public function addLuaSprite(tag:String, front:Bool = true) {
        if(utilInstGet("modchartSprites").exists(tag)) {
            var shit:ModchartSprite = utilInstGet("modchartSprites").get(tag);
            if(!shit.wasAdded) {
                if(!isPlayState || front )
                {
                    getInstance().add(shit);
                }
                else
                {
					if(playInstance.isDead)
                    {
                        GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
                    }
                    else
                    {
                        var position:Int = playInstance.members.indexOf(playInstance.gfGroup);
                        if(getMembers().indexOf(playInstance.boyfriendGroup) < position) {
                            position = playInstance.members.indexOf(playInstance.boyfriendGroup);
                        } else if(getMembers().indexOf(playInstance.dadGroup) < position) {
                            position = playInstance.members.indexOf(playInstance.dadGroup);
                        }
                        playInstance.insert(position, shit);
                    }
                }
                shit.wasAdded = true;
                //trace('added a thing: ' + tag);
            }
        }
    }
    public function setGraphicSize(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
        if(utilInst().getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInst().getLuaObject(obj);
            shit.setGraphicSize(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var killMe:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(poop != null) {
            poop.setGraphicSize(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function scaleObject(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
        if(utilInst().getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInst().getLuaObject(obj);
            shit.scale.set(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var killMe:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(poop != null) {
            poop.scale.set(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function updateHitbox(obj:String) {
        if(utilInst().getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInst().getLuaObject(obj);
            shit.updateHitbox();
            return;
        }

        var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(poop != null) {
            poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function updateHitboxFromGroup(group:String, index:Int) {
        if(Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup)) {
            Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
            return;
        }
        Reflect.getProperty(getInstance(), group)[index].updateHitbox();
    }

    public function isNoteChild(parentID:Int, childID:Int){
        var parent: Note = cast utilInst().getLuaObject('note${parentID}',false);
        var child: Note = cast utilInst().getLuaObject('note${childID}',false);
        if(parent!=null && child!=null)
            return parent.tail.contains(child);

        funkyTrace('${parentID} or ${childID} is not a valid note ID', false, false, FlxColor.RED);
        return false;
    }

    public function removeLuaSprite(tag:String, destroy:Bool = true) {
        if(!utilInstGet("modchartSprites").exists(tag)) {
            return;
        }

        var pee:ModchartSprite = utilInstGet("modchartSprites").get(tag);
        if(destroy) {
            pee.kill();
        }

        if(pee.wasAdded) {
            getInstance().remove(pee, true);
            pee.wasAdded = false;
        }

        if(destroy) {
            pee.destroy();
            utilInstGet("modchartSprites").remove(tag);
        }
    }

    public function luaSpriteExists(tag:String) {
        return utilInstGet("modchartSprites").exists(tag);
    }
    public function luaTextExists(tag:String) {
        return utilInstGet("modchartTexts").exists(tag);
    }
    public function luaSoundExists(tag:String) {
        return utilInstGet("modchartSounds").exists(tag);
    }

    public function setHealthBarColors(leftHex:String, rightHex:String) {
        if(!isPlayState) return;
		var left:FlxColor = Std.parseInt(leftHex);
        if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
        var right:FlxColor = Std.parseInt(rightHex);
        if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

        playInstance.healthBar.createFilledBar(left, right);
        playInstance.healthBar.updateBar();
    }
    public function setTimeBarColors(leftHex:String, rightHex:String) {
        if(!isPlayState) return;
		var left:FlxColor = Std.parseInt(leftHex);
        if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
        var right:FlxColor = Std.parseInt(rightHex);
        if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

        playInstance.timeBar.createFilledBar(right, left);
        playInstance.timeBar.updateBar();
    }

    public function setObjectCamera(obj:String, camera:String = '') {
        /*if(utilInstGet("modchartSprites").exists(obj)) {
            utilInstGet("modchartSprites").get(obj).cameras = [cameraFromString(camera)];
            return true;
        }
        else if(utilInstGet("modchartTexts").exists(obj)) {
            utilInstGet("modchartTexts").get(obj).cameras = [cameraFromString(camera)];
            return true;
        }*/
        var real = utilInst().getLuaObject(obj);
        if(real!=null){
            real.cameras = [cameraFromString(camera)];
            return true;
        }

        var killMe:Array<String> = obj.split('.');
        var object:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(object != null) {
            object.cameras = [cameraFromString(camera)];
            return true;
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
    }
    public function setBlendMode(obj:String, blend:String = '') {
        var real = utilInst().getLuaObject(obj);
        if(real!=null) {
            real.blend = blendModeFromString(blend);
            return true;
        }

        var killMe:Array<String> = obj.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null) {
            spr.blend = blendModeFromString(blend);
            return true;
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
    }
    public function screenCenter(obj:String, pos:String = 'xy') {
        var spr:FlxSprite = utilInst().getLuaObject(obj);

        if(spr==null){
            var killMe:Array<String> = obj.split('.');
            spr = getObjectDirectly(killMe[0]);
            if(killMe.length > 1) {
                spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
            }
        }

        if(spr != null)
        {
            switch(pos.trim().toLowerCase())
            {
                case 'x':
                    spr.screenCenter(X);
                    return;
                case 'y':
                    spr.screenCenter(Y);
                    return;
                default:
                    spr.screenCenter(XY);
                    return;
            }
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
    }
    public function objectsOverlap(obj1:String, obj2:String) {
        var namesArray:Array<String> = [obj1, obj2];
        var objectsArray:Array<FlxSprite> = [];
        for (i in 0...namesArray.length)
        {
            var real = utilInst().getLuaObject(namesArray[i]);
            if(real!=null) {
                objectsArray.push(real);
            } else {
                objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
            }
        }

        if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
        {
            return true;
        }
        return false;
    }
    public function getPixelColor(obj:String, x:Int, y:Int) {
        var killMe:Array<String> = obj.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null)
        {
            if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
            return spr.pixels.getPixel32(x, y);
        }
        return 0;
    }
    public function getRandomInt(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
        var excludeArray:Array<String> = exclude.split(',');
        var toExclude:Array<Int> = [];
        for (i in 0...excludeArray.length)
        {
            toExclude.push(Std.parseInt(excludeArray[i].trim()));
        }
        return FlxG.random.int(min, max, toExclude);
    }
    public function getRandomFloat(min:Float, max:Float = 1, exclude:String = '') {
        var excludeArray:Array<String> = exclude.split(',');
        var toExclude:Array<Float> = [];
        for (i in 0...excludeArray.length)
        {
            toExclude.push(Std.parseFloat(excludeArray[i].trim()));
        }
        return FlxG.random.float(min, max, toExclude);
    }
    public function getRandomBool(chance:Float = 50) {
        return FlxG.random.bool(chance);
    }
    public function startDialogue(dialogueFile:String, music:String = null) {
        if(!isPlayState) return false;
		var path:String;
        #if MODS_ALLOWED
        path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
        if(!FileSystem.exists(path))
        #end
            path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

        funkyTrace('Trying to load dialogue: ' + path);

        #if MODS_ALLOWED
        if(FileSystem.exists(path))
        #else
        if(Assets.exists(path))
        #end
        {
            var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
            if(shit.dialogue.length > 0) {
                playInstance.startDialogue(shit, music);
                funkyTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
                return true;
            } else {
                funkyTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
            }
        } else {
            funkyTrace('Dialogue file not found', false, false, FlxColor.RED);
            if(playInstance.endingSong) {
                playInstance.endSong();
            } else {
                playInstance.startCountdown();
            }
        }
        return false;
    }
    public function startVideo(videoFile:String) {
        #if VIDEOS_ALLOWED
        if(FileSystem.exists(Paths.video(videoFile))) {
            if(!isSubstate){
				cast(utilInst(),MusicBeatState).startVideo(videoFile);
			}
			else{
				//W: IGNORED, FOR NOW 
			}
            return true;
        } else {
            funkyTrace('Video file not found: ' + videoFile, false, false, FlxColor.RED);
        }
        return false;

        #else
		/*
        if(!isPlayState) return true;
		if(utilInst().endingSong) {
            utilInst().endSong();
        } else {
            utilInst().startCountdown();
        }
        return true;*/
		return false;
        #end
    }

    public function playMusic(sound:String, volume:Float = 1, loop:Bool = false) {
        FlxG.sound.playMusic(Paths.music(sound), volume, loop);
    }
    public function playSound(sound:String, volume:Float = 1, ?tag:String = null) {
        if(tag != null && tag.length > 0) {
            tag = tag.replace('.', '');
            if(utilInstGet("modchartSounds").exists(tag)) {
                utilInstGet("modchartSounds").get(tag).stop();
            }
            utilInstGet("modchartSounds").set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
                utilInstGet("modchartSounds").remove(tag);
                utilInst().callOnLuas('onSoundFinished', [tag]);
            }));
            return;
        }
        FlxG.sound.play(Paths.sound(sound), volume);
    }
    public function stopSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).stop();
            utilInstGet("modchartSounds").remove(tag);
        }
    }
    public function pauseSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).pause();
        }
    }
    public function resumeSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).play();
        }
    }
    public function soundFadeIn(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
        if(tag == null || tag.length < 1) {
            FlxG.sound.music.fadeIn(duration, fromValue, toValue);
        } else if(utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).fadeIn(duration, fromValue, toValue);
        }

    }
    public function soundFadeOut(tag:String, duration:Float, toValue:Float = 0) {
        if(tag == null || tag.length < 1) {
            FlxG.sound.music.fadeOut(duration, toValue);
        } else if(utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).fadeOut(duration, toValue);
        }
    }
    public function soundFadeCancel(tag:String) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music.fadeTween != null) {
                FlxG.sound.music.fadeTween.cancel();
            }
        } else if(utilInstGet("modchartSounds").exists(tag)) {
            var theSound:FlxSound = utilInstGet("modchartSounds").get(tag);
            if(theSound.fadeTween != null) {
                theSound.fadeTween.cancel();
                utilInstGet("modchartSounds").remove(tag);
            }
        }
    }
    public function getSoundVolume(tag:String) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music != null) {
                return FlxG.sound.music.volume;
            }
        } else if(utilInstGet("modchartSounds").exists(tag)) {
            return utilInstGet("modchartSounds").get(tag).volume;
        }
        return 0;
    }
    public function setSoundVolume(tag:String, value:Float) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music != null) {
                FlxG.sound.music.volume = value;
            }
        } else if(utilInstGet("modchartSounds").exists(tag)) {
            utilInstGet("modchartSounds").get(tag).volume = value;
        }
    }
    public function getSoundTime(tag:String) {
        if(tag != null && tag.length > 0 && utilInstGet("modchartSounds").exists(tag)) {
            return utilInstGet("modchartSounds").get(tag).time;
        }
        return 0;
    }
    public function setSoundTime(tag:String, value:Float) {
        if(tag != null && tag.length > 0 && utilInstGet("modchartSounds").exists(tag)) {
            var theSound:FlxSound = utilInstGet("modchartSounds").get(tag);
            if(theSound != null) {
                var wasResumed:Bool = theSound.playing;
                theSound.pause();
                theSound.time = value;
                if(wasResumed) theSound.play();
            }
        }
    }

    public function debugPrint(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
        if (text1 == null) text1 = '';
        if (text2 == null) text2 = '';
        if (text3 == null) text3 = '';
        if (text4 == null) text4 = '';
        if (text5 == null) text5 = '';
        funkyTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
    }
    

    public function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
        #if desktop
        DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
        #end
    }


    // LUA TEXTS
    public function makeLuaText(tag:String, text:String, width:Int, x:Float, y:Float) {
        tag = tag.replace('.', '');
        resetTextTag(tag);
        var leText:ModchartText = new ModchartText(x, y, text, width);
        utilInstGet("modchartTexts").set(tag, leText);
    }

    public function setTextString(tag:String, text:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.text = text;
        }
    }
    public function setTextSize(tag:String, size:Int) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.size = size;
        }
    }
    public function setTextWidth(tag:String, width:Float) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.fieldWidth = width;
        }
    }
    public function setTextBorder(tag:String, size:Int, color:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            obj.borderSize = size;
            obj.borderColor = colorNum;
        }
    }
    public function setTextColor(tag:String, color:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            obj.color = colorNum;
        }
    }
    public function setTextFont(tag:String, newFont:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.font = Paths.font(newFont);
        }
    }
    public function setTextItalic(tag:String, italic:Bool) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.italic = italic;
        }
    }
    public function setTextAlignment(tag:String, alignment:String = 'left') {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.alignment = LEFT;
            switch(alignment.trim().toLowerCase())
            {
                case 'right':
                    obj.alignment = RIGHT;
                case 'center':
                    obj.alignment = CENTER;
            }
        }
    }

    public function getTextString(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null && obj.text != null)
        {
            return obj.text;
        }
        return null;
    }
    public function getTextSize(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.size;
        }
        return -1;
    }
    public function getTextFont(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.font;
        }
        return null;
    }
    public function getTextWidth(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.fieldWidth;
        }
        return 0;
    }

    public function addLuaText(tag:String) {
        if(utilInstGet("modchartTexts").exists(tag)) {
            var shit:ModchartText = utilInstGet("modchartTexts").get(tag);
            if(!shit.wasAdded) {
                getInstance().add(shit);
                shit.wasAdded = true;
                //trace('added a thing: ' + tag);
            }
        }
    }
    public function removeLuaText(tag:String, destroy:Bool = true) {
        if(!utilInstGet("modchartTexts").exists(tag)) {
            return;
        }

        var pee:ModchartText = utilInstGet("modchartTexts").get(tag);
        if(destroy) {
            pee.kill();
        }

        if(pee.wasAdded) {
            getInstance().remove(pee, true);
            pee.wasAdded = false;
        }

        if(destroy) {
            pee.destroy();
            utilInstGet("modchartTexts").remove(tag);
        }
    }

    public function initSaveData(name:String, ?folder:String = 'psychenginemods') {
        if(!utilInstGet("modchartSaves").exists(name))
        {
            var save:FlxSave = new FlxSave();
            save.bind(name, folder);
            utilInstGet("modchartSaves").set(name, save);
            return;
        }
        funkyTrace('Save file already initialized: ' + name);
    }
    public function flushSaveData(name:String) {
        if(utilInstGet("modchartSaves").exists(name))
        {
            utilInstGet("modchartSaves").get(name).flush();
            return;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
    }
    public function getDataFromSave(name:String, field:String, ?defaultValue:Dynamic = null) {
        if(utilInstGet("modchartSaves").exists(name))
        {
            var retVal:Dynamic = Reflect.field(utilInstGet("modchartSaves").get(name).data, field);
            return retVal;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
        return defaultValue;
    }
    public function setDataFromSave(name:String, field:String, value:Dynamic) {
        if(utilInstGet("modchartSaves").exists(name))
        {
            Reflect.setField(utilInstGet("modchartSaves").get(name).data, field, value);
            return;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
    }

    public function checkFileExists(filename:String, ?absolute:Bool = false) {
        #if MODS_ALLOWED
        if(absolute)
        {
            return FileSystem.exists(filename);
        }

        var path:String = Paths.modFolders(filename);
        if(FileSystem.exists(path))
        {
            return true;
        }
        return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
        #else
        if(absolute)
        {
            return Assets.exists(filename);
        }
        return Assets.exists(Paths.getPath('assets/$filename', TEXT));
        #end
    }
    public function saveFile(path:String, content:String, ?absolute:Bool = false)
    {
        try {
            if(!absolute)
                File.saveContent(Paths.mods(path), content);
            else
                File.saveContent(path, content);

            return true;
        } catch (e:Dynamic) {
            funkyTrace("Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
        }
        return false;
    }
    public function deleteFile(path:String, ?ignoreModFolders:Bool = false)
    {
        try {
            #if MODS_ALLOWED
            if(!ignoreModFolders)
            {
                var lePath:String = Paths.modFolders(path);
                if(FileSystem.exists(lePath))
                {
                    FileSystem.deleteFile(lePath);
                    return true;
                }
            }
            #end

            var lePath:String = Paths.getPath(path, TEXT);
            if(Assets.exists(lePath))
            {
                FileSystem.deleteFile(lePath);
                return true;
            }
        } catch (e:Dynamic) {
            funkyTrace("Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
        }
        return false;
    }
    public function getTextFromFile(path:String, ?ignoreModFolders:Bool = false) {
        return Paths.getTextFromFile(path, ignoreModFolders);
    }

    // DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
    public function objectPlayAnimation(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
        funkyTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
        if(utilInst().getLuaObject(obj,false) != null) {
            utilInst().getLuaObject(obj,false).animation.play(name, forced, false, startFrame);
            return true;
        }

        var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(spr != null) {
            spr.animation.play(name, forced, false, startFrame);
            return true;
        }
        return false;
    }
    public function characterPlayAnim(character:String, anim:String, ?forced:Bool = false) {
        if(!isPlayState) return;
		funkyTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
        switch(character.toLowerCase()) {
            case 'dad':
                if(playInstance.dad.animOffsets.exists(anim))
                    playInstance.dad.playAnim(anim, forced);
            case 'gf' | 'girlfriend':
                if(playInstance.gf != null && playInstance.gf.animOffsets.exists(anim))
                    playInstance.gf.playAnim(anim, forced);
            default:
                if(playInstance.boyfriend.animOffsets.exists(anim))
                    playInstance.boyfriend.playAnim(anim, forced);
        }
    }
    public function luaSpriteMakeGraphic(tag:String, width:Int, height:Int, color:String) {
        funkyTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            utilInstGet("modchartSprites").get(tag).makeGraphic(width, height, colorNum);
        }
    }
    public function luaSpriteAddAnimationByPrefix(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
        funkyTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var cock:ModchartSprite = utilInstGet("modchartSprites").get(tag);
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }
    public function luaSpriteAddAnimationByIndices(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        funkyTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var strIndices:Array<String> = indices.trim().split(',');
            var die:Array<Int> = [];
            for (i in 0...strIndices.length) {
                die.push(Std.parseInt(strIndices[i]));
            }
            var pussy:ModchartSprite = utilInstGet("modchartSprites").get(tag);
            pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
        }
    }
    public function luaSpritePlayAnimation(tag:String, name:String, forced:Bool = false) {
        funkyTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            utilInstGet("modchartSprites").get(tag).animation.play(name, forced);
        }
    }
    public function setLuaSpriteCamera(tag:String, camera:String = '') {
        funkyTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            utilInstGet("modchartSprites").get(tag).cameras = [cameraFromString(camera)];
            return true;
        }
        funkyTrace("Lua sprite with tag: " + tag + " doesn't exist!");
        return false;
    }
    public function setLuaSpriteScrollFactor(tag:String, scrollX:Float, scrollY:Float) {
        funkyTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            utilInstGet("modchartSprites").get(tag).scrollFactor.set(scrollX, scrollY);
            return true;
        }
        return false;
    }
    public function scaleLuaSprite(tag:String, x:Float, y:Float) {
        funkyTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var shit:ModchartSprite = utilInstGet("modchartSprites").get(tag);
            shit.scale.set(x, y);
            shit.updateHitbox();
            return true;
        }
        return false;
    }
    public function getPropertyLuaSprite(tag:String, variable:String) {
        funkyTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var killMe:Array<String> = variable.split('.');
            if(killMe.length > 1) {
                var coverMeInPiss:Dynamic = Reflect.getProperty(utilInstGet("modchartSprites").get(tag), killMe[0]);
                for (i in 1...killMe.length-1) {
                    coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
                }
                return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
            }
            return Reflect.getProperty(utilInstGet("modchartSprites").get(tag), variable);
        }
        return null;
    }

	public function setProperty(variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			setVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
			return true;
		}
		setVarInArray(getInstance(), variable, value);
		return true;
	}

    public function setPropertyLuaSprite(tag:String, variable:String, value:Dynamic) {
        funkyTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
        if(utilInstGet("modchartSprites").exists(tag)) {
            var killMe:Array<String> = variable.split('.');
            if(killMe.length > 1) {
                var coverMeInPiss:Dynamic = Reflect.getProperty(utilInstGet("modchartSprites").get(tag), killMe[0]);
                for (i in 1...killMe.length-1) {
                    coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
                }
                Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
                return true;
            }
            Reflect.setProperty(utilInstGet("modchartSprites").get(tag), variable, value);
            return true;
        }
        funkyTrace("Lua sprite with tag: " + tag + " doesn't exist!");
        return false;
    }
    public function musicFadeIn(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
        FlxG.sound.music.fadeIn(duration, fromValue, toValue);
        funkyTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

    }
    public function musicFadeOut(duration:Float, toValue:Float = 0) {
        FlxG.sound.music.fadeOut(duration, toValue);
        funkyTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
    }

    // Other stuff
    public function stringStartsWith(str:String, start:String) {
        return str.startsWith(start);
    }
    public function stringEndsWith(str:String, end:String) {
        return str.endsWith(end);
    }
    public function stringSplit(str:String, split:String) {
        return str.split(split);
    }
    public function stringTrim(str:String) {
        return str.trim();
    }
    
    public function directoryFileList(folder:String) {
        var list:Array<String> = [];
        #if sys
        if(FileSystem.exists(folder)) {
            for (folder in FileSystem.readDirectory(folder)) {
                if (!list.contains(folder)) {
                    list.push(folder);
                }
            }
        }
        #end
        return list;
    }
    //}
}