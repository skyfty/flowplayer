/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Daniel Rossi, <electroteque@gmail.com>
 * Copyright (c) 2009 Electroteque Multimedia35
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.optionsdialog {
    import com.adobe.serialization.json.JSON;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.net.navigateToURL;
    import flash.text.TextField;
    import flash.utils.Timer;
    import org.flowplayer.util.StyleSheetUtil;
    import org.flowplayer.ui.buttons.LabelButton;
    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.ui.buttons.ButtonConfig;
    import org.flowplayer.util.URLUtil;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.optionsdialog.config.Config;
    import org.flowplayer.util.Arrange;

    internal class OpenView extends StyleableView {

        private var _optionDilaog:OptionsDialog;
        private var _formContainer:Sprite;
        private var _openFileBtn:LabelButton;
        private var _openUrlBtn:LabelButton;
        private var _openLiveBtn:LabelButton;
        private var _config:Config;

        private var _openfileInputBg:Sprite;
        private var _titleLabel:TextField;
        private var _videoURL:String;
        private var _videoURLInput:TextField;
        private var _openBtn:LabelButton;
        private var _cancelBtn:LabelButton;

        public function OpenView(od:OptionsDialog, plugin:DisplayPluginModel, player:Flowplayer, conf:Config) {
            super("viral-open", plugin, player, conf.canvas);
            _config = conf;
            _optionDilaog = od;

            _formContainer = new Sprite();
            addChild(_formContainer);

            _openFileBtn = new LabelButton("打开文件",  Config.defaultButtonConfig(), player.animationEngine);
            _openFileBtn.visible = true;
            _openFileBtn.enabled = false;
            _openFileBtn.addEventListener(MouseEvent.CLICK, onOpenFile);
            _formContainer.addChild(_openFileBtn);
            
            _openUrlBtn = new LabelButton("打开URL",  Config.defaultButtonConfig(), player.animationEngine);
            _openUrlBtn.visible = true;
            _openUrlBtn.addEventListener(MouseEvent.CLICK, onOpenUrl);
            _formContainer.addChild(_openUrlBtn);

            _openLiveBtn = new LabelButton("打开直播",  Config.defaultButtonConfig(), player.animationEngine);
            _openLiveBtn.visible = true;
            _openLiveBtn.enabled = false;
            _openLiveBtn.addEventListener(MouseEvent.CLICK, onOpenLive);
            _formContainer.addChild(_openLiveBtn);
 


            _openfileInputBg = new Sprite();
            addChild(_openfileInputBg);

            _titleLabel = createLabelField();
            _titleLabel.visible = true;
            _titleLabel.htmlText = "<span class=\"title\">网络地址</span>";
            _openfileInputBg.addChild(_titleLabel);

            _openBtn = new LabelButton("打开", Config.defaultButtonConfig(), player.animationEngine);
            _openBtn.addEventListener(MouseEvent.CLICK, onOpenUrlInput);
            _openfileInputBg.addChild(_openBtn);

            _cancelBtn = new LabelButton("取消", Config.defaultButtonConfig(), player.animationEngine);
            _cancelBtn.addEventListener(MouseEvent.CLICK, onCancel);
            _openfileInputBg.addChild(_cancelBtn);

            _videoURLInput = createInputField();
            _videoURLInput.multiline = true;
            _videoURLInput.mouseWheelEnabled = true;
            _openfileInputBg.addChild(_videoURLInput);

            init();
        }

        public function init():void {

            _formContainer.visible = true;
            _openfileInputBg.visible = false;
        }

        private function onOpenFile(event:MouseEvent):void {

        }


        private function onOpenUrl(event:MouseEvent):void {
            _formContainer.visible = false;

            _openfileInputBg.visible = true;
            _videoURLInput.text = "";

            onResize();
        }
        
        private function onOpenLive(event:MouseEvent):void {

        }
        
        private function onOpenUrlInput(event:MouseEvent):void {

            _optionDilaog.visible = false; 
            player.genericPlay(_videoURLInput.text);
            onCancel(event);
        }

        private function onCancel(event:MouseEvent):void {
            _openfileInputBg.visible = false;
            _formContainer.visible = true;
            onResize();
        }

        override protected function onResize():void {

            _openFileBtn.setSize(100, 25);
            _openFileBtn.x = 10;
            _openFileBtn.y = 60;

            _openUrlBtn.setSize(100, 25);
            _openUrlBtn.x = _openFileBtn.x + _openFileBtn.width + 10;
            _openUrlBtn.y = 60;

            _openLiveBtn.setSize(100, 25);
            _openLiveBtn.x = _openUrlBtn.x + _openUrlBtn.width + 10;;
            _openLiveBtn.y = 60;

            if (_openfileInputBg.visible) {
                _openfileInputBg.graphics.clear();
                _openfileInputBg.graphics.beginFill(
                    StyleSheetUtil.colorValue("rgba(39,39, 39)"), 
                    StyleSheetUtil.colorAlpha("rgba(39,39, 39)"));
                _openfileInputBg.graphics.drawRect(0, 0, width, height);
                _openfileInputBg.graphics.endFill();     

                if (_titleLabel) {
                    _titleLabel.width =  30;
                    _titleLabel.x = 200;
                    _titleLabel.y = 60;       
                 }            

                if (_videoURLInput) {
                    _videoURLInput.width =  width - 50;
                    _videoURLInput.height = 120;
                    Arrange.center(_videoURLInput, width, height);               
                }     

                if (_openBtn) {
                    _openBtn.setSize(80, 20);
                    _openBtn.x = 150;
                    _openBtn.y = _videoURLInput.y + _videoURLInput.height+ 10;             
                }      

                if (_cancelBtn) {
                    _cancelBtn.setSize(80, 20);
                    _cancelBtn.x = _openBtn.x + _cancelBtn.width + 5;
                    _cancelBtn.y = _openBtn.y;             
                }            
            }
        }
    }
}
