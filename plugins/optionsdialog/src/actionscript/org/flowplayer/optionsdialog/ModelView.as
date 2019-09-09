
package org.flowplayer.optionsdialog {
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.FocusEvent;
    import flash.events.MouseEvent;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.external.ExternalInterface;
    import org.flowplayer.model.PlayerEvent;
    import org.flowplayer.model.PlayerEventType;
    import org.flowplayer.model.ClipType;
    import org.flowplayer.model.ClipEventType;
    import org.flowplayer.model.ClipEvent;
    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.ui.buttons.ButtonConfig;
    import org.flowplayer.ui.buttons.LabelButton;
    import org.flowplayer.util.Arrange;
    import org.flowplayer.view.AnimationEngine;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.optionsdialog.config.Config;

    /**
     * @author danielr
     */
    internal class ModelView extends StyleableView {
        private var Y_ALIGN:int = 60;
        private var _formContainer:Sprite;

        private var _fullscreenBtn:LabelButton;
        private var _cinemaBtn:LabelButton;
        private var _windowsBtn:LabelButton;

        private var _videoURL:String;
        private var _config:Config;

        public function ModelView(plugin:DisplayPluginModel, player:Flowplayer, conf:Config) {
            super("viral-model", plugin, player, conf.canvas);
            _config = conf;
            _formContainer = new Sprite();
            addChild(_formContainer);
  
            player.onFullscreen(onPlayerFullscreen);
            player.onFullscreenExit(onPlayerFullscreen);
  
            createButton();
        }

        public function init():void {
            
        }
        
        private function createButton() : void {
            _fullscreenBtn = new LabelButton("全屏模式",  Config.defaultButtonConfig(), player.animationEngine);
            _fullscreenBtn.addEventListener(MouseEvent.CLICK, onFullScreenMode);
            _formContainer.addChild(_fullscreenBtn);
            
            _cinemaBtn = new LabelButton("影院模式",  Config.defaultButtonConfig(), player.animationEngine);
            _cinemaBtn.addEventListener(MouseEvent.CLICK, onCinemaMode);
            _formContainer.addChild(_cinemaBtn);

            _windowsBtn = new LabelButton("窗口模式",  Config.defaultButtonConfig(), player.animationEngine);
            _windowsBtn.addEventListener(MouseEvent.CLICK, onWinodwsMode);
            _formContainer.addChild(_windowsBtn);
        }

        private function onFullScreenMode(event:MouseEvent):void {
            if (!player.isFullscreen()) {
                player.toggleFullscreen();
            }
        }

        private function onCinemaMode(event:MouseEvent):void {
            
            if (!player.isFullscreen()) {
                player.toggleFullscreen();
            }
        }
        
        private function onWinodwsMode(event:MouseEvent):void {
 
            player.close();;
            var callbackFunction:String = 
                "function(obj, url) {" +
                "  if (typeof onOpenWindowMode == 'function') { " +
                "    onOpenWindowMode(obj, url); " +
                "  } " +
                "} ";
            ExternalInterface.call(
                callbackFunction,  
                ExternalInterface.objectID, player.currentClip.completeUrl);
        }

        protected function onPlayerFullscreen(event:PlayerEvent):void {
            _fullscreenBtn.enabled = !player.isFullscreen(); 
            arrangeButton();
        }


        private function arrangeButton():void {
            _fullscreenBtn.setSize(100, 25);
            _fullscreenBtn.x = 10;
            _fullscreenBtn.y = Y_ALIGN;
          
            _cinemaBtn.setSize(100, 25);
            _cinemaBtn.x = _fullscreenBtn.x + _fullscreenBtn.width + 10;
            _cinemaBtn.y = Y_ALIGN;

            _windowsBtn.setSize(100, 25);
            _windowsBtn.x = _cinemaBtn.x + _cinemaBtn.width + 10;;
            _windowsBtn.y = Y_ALIGN;
        }

        override protected function onResize():void {
            log.debug("onResize " + width + " x " + height);
            arrangeButton();
        }
    }
}
