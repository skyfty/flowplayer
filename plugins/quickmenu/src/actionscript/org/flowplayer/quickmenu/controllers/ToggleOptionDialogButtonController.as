package org.flowplayer.quickmenu.controllers {
    
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.model.PlayerEvent;
    import org.flowplayer.model.ClipEvent;
    import org.flowplayer.model.Clip;
    import org.flowplayer.model.PlayerEventType;
    
    import org.flowplayer.ui.buttons.ToggleButtonConfig;
    import org.flowplayer.ui.controllers.AbstractToggleButtonController;

    import org.flowplayer.ui.buttons.ButtonEvent;
    import org.flowplayer.ui.buttons.ToggleButton;
    
    import org.flowplayer.quickmenu.QuickMenubar;
    import org.flowplayer.quickmenu.SkinClasses;

    import flash.display.DisplayObjectContainer;
    
    public class ToggleOptionDialogButtonController extends AbstractToggleButtonController {
        
        public function ToggleOptionDialogButtonController() {
            super();
        }
        
        override public function get name():String {
            return "optiondialog";
        }

        override public function get defaults():Object {
            return {
                tooltipEnabled: true,
                tooltipLabel: "菜单",
                visible: true,
                enabled: true
            };
        }
        
        override public function get downName():String {
            return "OptionDialogExit";
        }
        
        override public function get downDefaults():Object {
            return {
                tooltipEnabled: false,
                tooltipLabel: "菜单",
                visible: true,
                enabled: true
            };
        }

        override protected function get faceClass():Class {
            return SkinClasses.getClass("fp.OptionDialogOnButton");
        }
        
        override protected function get downFaceClass():Class {
            return SkinClasses.getClass("fp.OptionDialogOnButton");
        }       
         
        
        // TODO : this guy might need to be moved
        protected function doEnable(clip:Clip):void {
            var shouldEnable:Boolean = clip && (clip.originalWidth > 0 || ! clip.useHWScaling) && _config.config.enabled;
            _widget.enabled     = shouldEnable;
        }
        
        // Fullscreen related stuff
        override protected function addPlayerListeners():void {
            super.addPlayerListeners();
            
            _player.onFullscreen(onPlayerFullscreen);
            _player.onFullscreenExit(onPlayerFullscreen);
        }
        
        protected function onPlayerFullscreen(event:PlayerEvent):void {
            isDown = event.eventType == PlayerEventType.FULLSCREEN;
        }

        override protected function onPlayStarted(event:ClipEvent):void {
            doEnable(event.target as Clip);
        }


        override protected function onButtonClicked(event:ButtonEvent):void {
            var optonsDialog:Object = _player.pluginRegistry.getPlugin("optionsdialog");
            if (optonsDialog == null)
                return;
            optonsDialog.pluginObject.doModel("打开");
        }
    }
}
