package funkin.ui.mainmenu;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.group.FlxTypedGroup;
import flixel.FlxCamera;
import flixel.FlxG;
import funkin.graphics.FunkinCamera;
import funkin.ui.MusicBeatState;
import funkin.audio.FunkinSound;
import funkin.ui.story.StoryMenuState;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.title.TitleState;

class MainMenuState extends MusicBeatState {
    var menuItems:FlxTypedGroup<FlxSprite>;
    var camFollow:FlxObject;
    var deluxeMenu:FlxSprite; // Sprite dinámico del lado izquierdo
    var overrideMusic:Bool = false;

    static var rememberedSelectedIndex:Int = 0;

    public function new(?_overrideMusic:Bool = false) {
        super();
        overrideMusic = _overrideMusic;
    }

    override function create():Void {
        FlxG.cameras.reset(new FunkinCamera("mainMenu"));

        // Transiciones
        transIn = FlxCamera.defaultTransIn;
        transOut = FlxCamera.defaultTransOut;

        if (!overrideMusic) playMenuMusic();

        persistentUpdate = true;
        persistentDraw = true;

        // Fondo del menú
        var bg = new FlxSprite();
        bg.loadGraphic("assets/images/menuBG.png");
        bg.scrollFactor.set(0, 0.17);
        bg.setGraphicSize(Std.int(bg.width * 1.2));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // Objeto para seguimiento de cámara
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        // Agregar el sprite dinámico "deluxeMenu"
        deluxeMenu = new FlxSprite(-200, FlxG.height * 0.5 - 100); // Posición inicial fuera de pantalla
        deluxeMenu.loadGraphic("assets/images/deluxeMenu.png");
        deluxeMenu.setGraphicSize(200, 200);
        deluxeMenu.alpha = 0; // Inicia invisible
        add(deluxeMenu);

        // Animación de entrada del deluxeMenu
        FlxTween.tween(deluxeMenu, {x: FlxG.width * 0.1, alpha: 1}, 1.0, {ease: FlxEase.quadOut});

        // Configurar los elementos del menú
        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);

        createMenuItem("storymode", "mainmenu/storymode", function() startExitState(() -> new StoryMenuState()));
        createMenuItem("freeplay", "mainmenu/freeplay", function() {
            persistentDraw = true;
            persistentUpdate = false;
            FlxG.switchState(() -> new FreeplayState());
        });
        createMenuItem("credits", "mainmenu/credits", function() {
            startExitState(() -> new TitleState());
        });

        // Posicionar los elementos del menú
        var spacing = 100;
        var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
        for (i in 0...menuItems.length) {
            var item = menuItems.members[i];
            item.x = FlxG.width / 2;
            item.y = top + spacing * i;
            item.scrollFactor.set(0.0, 0.4);
        }

        menuItems.selectItem(rememberedSelectedIndex);

        resetCamStuff();

        // Eventos dinámicos
        subStateOpened.add(sub -> {
            if (Type.getClass(sub) == FreeplayState) {
                new FlxTimer().start(0.5, _ -> deluxeMenu.alpha = 0); // Desaparece el deluxeMenu
            }
        });

        super.create();
    }

    function playMenuMusic():Void {
        FunkinSound.playMusic("freakyMenu", {
            overrideExisting: true,
            restartTrack: false
        });
    }

    function resetCamStuff():Void {
        FlxG.camera.follow(camFollow, null, 0.06);
        FlxG.camera.snapToTarget();
    }

    function createMenuItem(name:String, atlas:String, callback:Void->Void):Void {
        var item = new FlxSprite();
        item.loadGraphic("assets/images/" + atlas + ".png");
        item.centered = true;
        item.changeAnim("idle");
        item.ID = menuItems.length;
        menuItems.add(item);
        item.onMouseUp(callback); // Callback cuando el usuario selecciona el ítem
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Sincronización con el ritmo de la música
        if (FlxG.sound.music != null && FlxG.sound.music.isPlaying && FlxG.sound.music.position % 500 < 30) {
            FlxTween.tween(deluxeMenu.scale, {x: 1.1, y: 1.1}, 0.2, {ease: FlxEase.quadOut, onComplete: function() {
                FlxTween.tween(deluxeMenu.scale, {x: 1.0, y: 1.0}, 0.2, {ease: FlxEase.quadIn});
            }});
        }

        // Actualizar el seguimiento de la cámara al elemento seleccionado
        if (menuItems.selected != null) {
            camFollow.setPosition(menuItems.selected.x + menuItems.selected.width / 2, menuItems.selected.y + menuItems.selected.height / 2);
        }
    }

    function startExitState(state:Void->Void):Void {
        menuItems.enabled = false;
        rememberedSelectedIndex = menuItems.selectedIndex;

        var duration = 0.4;
        FlxTween.tween(deluxeMenu, {alpha: 0}, duration, {ease: FlxEase.quadOut}); // Animación de salida del deluxeMenu
        new FlxTimer().start(duration, function(_) FlxG.switchState(state));
    }

    override function closeSubState():Void {
        deluxeMenu.alpha = 0;
        super.closeSubState();
    }
}
