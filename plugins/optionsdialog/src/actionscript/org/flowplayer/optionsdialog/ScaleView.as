package org.flowplayer.optionsdialog {
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.external.ExternalInterface;
    import flash.display.Sprite;
    import flash.events.FocusEvent;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import org.flowplayer.model.ClipType;
    import org.flowplayer.model.ClipEventType;
    import org.flowplayer.model.ClipEvent;
    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.model.PluginError;
    import org.flowplayer.model.PluginEventType;
    import org.flowplayer.ui.buttons.AbstractButton;
    import org.flowplayer.util.Arrange;
    import org.flowplayer.util.URLUtil;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.ui.buttons.ButtonConfig;
    import org.flowplayer.ui.buttons.LabelButton;
    import org.flowplayer.optionsdialog.config.Config;
    import flash.display.BitmapData;
    internal class ScaleView extends StyleableView {

    private var _formContainer:Sprite;
        private var _originalBtn:LabelButton;
        private var _smoothBtn:LabelButton;
        private var _b05Btn:LabelButton;
        private var _b1Btn:LabelButton;
        private var _b15Btn:LabelButton;
        private var _b2Btn:LabelButton;
        private var _videoURL:String;
        private var _config:Config;

        private var _b16b9Btn:LabelButton;
        private var _b4b3Btn:LabelButton;

        public function ScaleView(plugin:DisplayPluginModel, player:Flowplayer, conf:Config) {
            super("viral-scale", plugin, player, conf.canvas);
             _config = conf;

           _formContainer = new Sprite();
            addChild(_formContainer);
 
            createButton();
        }

        public function init():void {
            
        }
        
        private function createLabel(htmlText:String = null, parent:DisplayObject = null):TextField {
            var field:TextField = createLabelField();
            if (htmlText != null) {
                field.htmlText = htmlText;
            }
            (parent ? parent : this).addChild(field);
            return field;
        }

        private function createButton() : void {
            _originalBtn = new LabelButton("原始比例（推荐)", Config.defaultButtonConfig(), player.animationEngine);
            _originalBtn.addEventListener(MouseEvent.CLICK, onOrigialScale);
            _formContainer.addChild(_originalBtn);

            _b16b9Btn = new LabelButton("16:9", Config.defaultButtonConfig(), player.animationEngine);
            _b16b9Btn.addEventListener(MouseEvent.CLICK, on16b9Scale);
            _formContainer.addChild(_b16b9Btn);

            _smoothBtn = new LabelButton("铺满窗口", Config.defaultButtonConfig(), player.animationEngine);
            _smoothBtn.addEventListener(MouseEvent.CLICK, onFullWindow);
            _formContainer.addChild(_smoothBtn);

            _b4b3Btn = new LabelButton("4:3", Config.defaultButtonConfig(), player.animationEngine);
            _b4b3Btn.addEventListener(MouseEvent.CLICK, on4b3Scale);
            _formContainer.addChild(_b4b3Btn);

            _b05Btn = new LabelButton("0.5倍", Config.defaultButtonConfig(), player.animationEngine);
            _b05Btn.addEventListener(MouseEvent.CLICK, onB05B);
            _formContainer.addChild(_b05Btn);
        
            _b1Btn = new LabelButton("1倍", Config.defaultButtonConfig(), player.animationEngine);
            _b1Btn.addEventListener(MouseEvent.CLICK, onB1B);
            _formContainer.addChild(_b1Btn);
        
            _b15Btn = new LabelButton("1.5倍", Config.defaultButtonConfig(), player.animationEngine);
            _b15Btn.addEventListener(MouseEvent.CLICK, onB15B);
            _formContainer.addChild(_b15Btn);
        
            _b2Btn = new LabelButton("2倍", Config.defaultButtonConfig(), player.animationEngine);
            _b2Btn.addEventListener(MouseEvent.CLICK, onB2B);
            _formContainer.addChild(_b2Btn);
        }

        private function onOrigialScale(event:MouseEvent):void {
            player.currentClip.setScaling("fit");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));
        }
        
        private function on16b9Scale(event:MouseEvent):void {
            player.currentClip.setScaling("scale16b9");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));
        }

        private function on4b3Scale(event:MouseEvent):void {
            player.currentClip.setScaling("scale4b3");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));
        }      
        private function onFullWindow(event:MouseEvent):void {
            player.currentClip.setScaling("scale");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));
        }
        
        private function onB05B(event:MouseEvent):void {
            player.currentClip.setScaling("scale05B");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));
        }
        private function onB1B(event:MouseEvent):void {
            player.currentClip.setScaling("scale1B");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));            
        }
        private function onB15B(event:MouseEvent):void {
            player.currentClip.setScaling("scale15B");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));            
        }
        private function onB2B(event:MouseEvent):void {
            player.currentClip.setScaling("scale2B");
            player.currentClip.dispatchEvent(new ClipEvent(ClipEventType.UPDATE));                
        }
        private function arrangeButton():void {
            _originalBtn.x = 30;
            _originalBtn.y = 35;
            _originalBtn.setSize(130, 25);
            
            _b16b9Btn.x = 255;
            _b16b9Btn.y = _originalBtn.y;
            _b16b9Btn.setSize(60, 25);
 
            _smoothBtn.x = 30;
            _smoothBtn.y = _originalBtn.y + _originalBtn.height + 15;
            _smoothBtn.setSize(100, 25);
            
            _b4b3Btn.x = 255;
            _b4b3Btn.y = _smoothBtn.y;
            _b4b3Btn.setSize(60, 25);

            _b05Btn.tabIndex = 5;        
            _b05Btn.x = 30;
            _b05Btn.y = _smoothBtn.y + _smoothBtn.height + 15;
            _b05Btn.setSize(60, 25);
            
            _b1Btn.tabIndex = 5;        
            _b1Btn.x = _b05Btn.x + _b05Btn.width + 15;
            _b1Btn.y = _b05Btn.y;
            _b1Btn.setSize(60, 25);

            _b15Btn.tabIndex = 5;        
            _b15Btn.x = _b1Btn.x + _b1Btn.width + 15;
            _b15Btn.y = _b1Btn.y;
            _b15Btn.setSize(60, 25);

            _b2Btn.tabIndex = 5;        
            _b2Btn.x = _b15Btn.x + _b15Btn.width + 15;
            _b2Btn.y = _b15Btn.y;
            _b2Btn.setSize(60, 25);
        }

        override protected function onResize():void {
            log.debug("onResize " + width + " x " + height);
            arrangeButton();
        }
    }
}
