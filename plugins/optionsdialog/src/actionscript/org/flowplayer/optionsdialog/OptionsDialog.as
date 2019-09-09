package org.flowplayer.optionsdialog {
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.model.PlayerEvent;
    import org.flowplayer.model.PlayerEventType;
    import org.flowplayer.model.Plugin;
    import org.flowplayer.model.PluginEventType;
    import org.flowplayer.model.PluginModel;
    import org.flowplayer.ui.buttons.CloseButton;
    import org.flowplayer.util.PropertyBinder;
    import org.flowplayer.view.AbstractSprite;
    import org.flowplayer.view.FlowStyleSheet;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.view.Styleable;
    import org.flowplayer.view.StyleableSprite;
    import org.flowplayer.optionsdialog.config.Config;
    import org.flowplayer.util.StyleSheetUtil;

    public class OptionsDialog extends AbstractSprite implements Plugin, Styleable {

        private const BORDER_BLANKING:int = 20;
        private const TAB_HEIGHT:int = 25;
        
        public const TAB_TITLE_OPEN:String = "打开";
        public const TAB_TITLE_MODEL:String = "播放模式";
        public const TAB_TITLE_SCALE:String = "画面比例";

        public var _player:Flowplayer;
        private var _model:PluginModel;
        private var _config:Config;

        private var _bgFill:Sprite;
        private var _tabContainer:Sprite;
        private var _panelContainer:Sprite;

        private var _modelView:ModelView;
        private var _openView:OpenView;
        private var _scaleView:ScaleView;
        private var _modelMask:Sprite = new Sprite();
        private var _openMask:Sprite = new Sprite();
        private var _scaleMask:Sprite = new Sprite();

        public var _modelTab:Tab;
        public var _openTab:Tab;
        public var _scaleTab:Tab;

        private var _closeButton:CloseButton;
        private var _tabCSSProperties:Object;

        private var _controls:Object;

        public function onConfig(plugin:PluginModel):void {
            log.debug("onConfig()", plugin.config);
            _model = plugin;
            _config = new PropertyBinder(new Config(), null).copyProperties(_model.config) as Config;
        }

        private function arrangeView(view:StyleableSprite):void {
            if (view) {
                view.setSize(width - BORDER_BLANKING * 2, 
                    height - TAB_HEIGHT - BORDER_BLANKING * 2);
                view.y = _tabContainer.y + TAB_HEIGHT;
                view.x = BORDER_BLANKING;
            }
        }

        private function arrangeCloseButton():void {
            _closeButton.width = width * .05;
            _closeButton.height = width * .05;
            _closeButton.y = 0 - _closeButton.width / 2;
            _closeButton.x = width - _closeButton.width / 2;
            setChildIndex(_closeButton, numChildren - 1);
        }

        override protected function onResize():void {
            if (_bgFill) {
                _bgFill.graphics.clear();
                _bgFill.graphics.beginFill(
                    StyleSheetUtil.colorValue("rgba(39,39, 39, 0.9)"), 
                    StyleSheetUtil.colorAlpha("rgba(39,39, 39, 0.9)"));
                _bgFill.graphics.drawRect(0, 0, width, height);
                _bgFill.graphics.endFill();    
            }
            
            arrangeView(_openView);
            arrangeView(_modelView);
            arrangeView(_scaleView);
            arrangeCloseButton();
        }

        private function createPanelContainer():void {
            _panelContainer = new Sprite();
            addChild(_panelContainer);
        }

        private function createCloseButton(icon:DisplayObject = null):void {
            if (_closeButton) return;
            _closeButton = new CloseButton(_config.closeButton, _player.animationEngine);
            addChild(_closeButton);
            _closeButton.addEventListener(MouseEvent.CLICK, close);
        }

       public function onLoad(player:Flowplayer):void {
            log.debug("onLoad()");
            
            this.visible = false;
            _player = player;

            _controls = _player.pluginRegistry.getPlugin("controls");
            
            _bgFill = new Sprite();
            addChild(_bgFill);

            createPanelContainer();
            createCloseButton();

            _player.onLoad(onPlayerLoad);
            _model.dispatchOnLoad();
        }
       public function doModel(view:String):void {
           
           //fix for #221 now pauses video on display of overlays
           if (_config.pauseVideo) _player.pause();
           
           var event:String = "onBeforeShow" + view;
           if (_model &&  !_model.dispatchBeforeEvent(PluginEventType.PLUGIN_EVENT, event)) {
               log.debug(event);
               return;
           }
           
           _openView.init();
           _scaleView.init();
           _modelView.init();

           this.alpha = 0;           
           this.visible = true;

           _player.setKeyboardShortcutsEnabled(false);
           setActiveTab(view);
           _player.animationEngine.fadeIn(this);
           _model.dispatch(PluginEventType.PLUGIN_EVENT, "onOptionModel");
       }

        private function onPlayerLoad(event:PlayerEvent):void {
            log.debug("onPlayerLoad() ");

            createViews();
            createTabs();

            hideViews();

            // show first view
            if ( _openView ) {
                setActiveTab(TAB_TITLE_OPEN, false);
            	_openView.show();
			} else if ( _modelView ) {
				setActiveTab(TAB_TITLE_MODEL, false);
            	_modelView.show();
			} else if ( _scaleView ) {
				setActiveTab(TAB_TITLE_SCALE, false);
            	_scaleView.show();
			}
        }

        private function createViews():void {
            createOpenView();
            createScaleView();
            createModelView();
        }

        public function getDefaultConfig():Object {
            return {
                top: "45%",
                left: "50%",
                opacity: 1,
                border: '1px',
                width: "375",
                height: "250"
            };
        }

        //Javascript API functions
        private function createOpenView():void {
            _openView = new OpenView(this, _model as DisplayPluginModel, _player,_config);
            _panelContainer.addChild(_openView);
        }

        private function createModelView():void {
            _modelView = new ModelView(_model as DisplayPluginModel, _player, _config);
            _panelContainer.addChild(_modelView);
        }


        private function createScaleView():void {
            _scaleView = new ScaleView(_model as DisplayPluginModel, _player, _config);
            _panelContainer.addChild(_scaleView);
        }

        private function hideViews():void {
            if (_openView) _openView.visible = false;
            if (_modelView) _modelView.visible = false;
            if (_scaleView) _scaleView.visible = false;
        }

        public function showView(panel:String):void {
            hideViews();

            if (panel == TAB_TITLE_OPEN && _openView) {
                _openView.show();
            }

            if (panel == TAB_TITLE_MODEL && _modelView) {
                _modelView.show();
            }

            if (panel == TAB_TITLE_SCALE && _scaleView) _scaleView.show();
        }

        private function onFullscreen(event:PlayerEvent):void {
            log.debug("preventing fullscreen");
            event.preventDefault();
        }

        //#410 toggle fullscreen and hide dock buttons for email and embed tabs
        private function toggleFullscreen():void
        {
            if (_player.isFullscreen()) {
                _player.toggleFullscreen();
            }
        }

        public function close(event:MouseEvent = null):void {
            _player.animationEngine.fadeOut(this, 500, onFadeOut);
        }

        private function onFadeOut():void {

            _player.setKeyboardShortcutsEnabled(true);

            //fix for #221 now pause / resume video when showing / hiding overlays
            if (_config.pauseVideo) _player.resume();

            _model.dispatch(PluginEventType.PLUGIN_EVENT, "onClose");
        }

        public function setActiveTab(newTab:String, show:Boolean = true):void {
            log.debug("setActiveTab() " + newTab);

            if (_openView) {
                _openMask.height = TAB_HEIGHT;
                _openTab.css({ backgroundGradient: 'medium', border: 'none'});
                _openTab.css({backgroundColor: 'rgba(0x00000000)'});
            }
            if (_modelView) {
                _modelMask.height = TAB_HEIGHT;
                _modelTab.css({ backgroundGradient: 'medium', border: 'none'});
                _modelTab.css({backgroundColor: 'rgba(0x00000000)'});
            }
            if (_scaleView) {
                _scaleMask.height = TAB_HEIGHT;
                _scaleTab.css({ backgroundGradient: 'medium', border: 'none'});
                _scaleTab.css({backgroundColor: 'rgba(0x00000000)'});
            }

            if (newTab == TAB_TITLE_OPEN && _openView) {
                _openMask.height = TAB_HEIGHT;
                _openTab.css({backgroundGradient: [.5, 0, 0.3]});
                _openTab.css({backgroundColor: 'rgba(0, 0, 0, 0.8)'});
            }
            if (newTab == TAB_TITLE_MODEL && _modelView) {
                _modelMask.height = TAB_HEIGHT;
                _modelTab.css({backgroundGradient: [.5, 0, 0.3]});
                _modelTab.css({backgroundColor: 'rgba(0, 0, 0, 0.8)'});
            }
            if (newTab == TAB_TITLE_SCALE && _scaleView) {
                _scaleMask.height = TAB_HEIGHT;
                _scaleTab.css({backgroundGradient: [.5, 0, 0.3]});
            }

            if (show) {
                showView(newTab);
            }
            arrangeView(getView(newTab));

        }

        private function getViewCSSProperties():Object {
            if (_openView) return _openView.css();
            if (_modelView) return _modelView.css();
            if (_scaleView) return _scaleView.css();
            return null;
        }

        private function createViewIfNotExists(liveTab:String, viewName:String, view:DisplayObject, createFunc:Function):void {
            if (liveTab == viewName && ! view) {
                createFunc();
            }
        }

        private function showViews(liveTab:String):void {
            this.visible = true;
            this.alpha = 1;
            _player.setKeyboardShortcutsEnabled(false);
            createViewIfNotExists(liveTab, TAB_TITLE_OPEN, _openView, createOpenView);
            createViewIfNotExists(liveTab, TAB_TITLE_MODEL, _modelView, createModelView);
            createViewIfNotExists(liveTab, TAB_TITLE_SCALE, _scaleView, createScaleView);

            setActiveTab(liveTab);
        }

        private function getView(liveTab:String):StyleableSprite {
            if (liveTab == TAB_TITLE_OPEN) return _openView;
            if (liveTab == TAB_TITLE_MODEL) return _modelView;
            if (liveTab == TAB_TITLE_SCALE) return _scaleView;
            return null;
        }

        private function createTab(xpos:int, mask:Sprite, tabTitle:String):Tab {
            var tab:Tab = new Tab(_model as DisplayPluginModel, _player, tabTitle, _config.canvas);
            tab.setSize(tabWidth, TAB_HEIGHT * 2);
            tab.x = xpos;
            _tabContainer.addChild(tab);

            mask.graphics.beginFill(0, 1);
            mask.graphics.drawRect(0, 0, tabWidth, TAB_HEIGHT * 2);
            mask.graphics.endFill();
            mask.x = xpos - 1;
            tab.mask = mask;
            _tabContainer.addChild(mask);
            return tab;
        }

        private function get tabWidth():Number {
            return width > 315 ? 100 : 80;
        }

        private function createTabs():void {
            log.debug("createTabs()");
            _tabContainer = new Sprite();
            addChild(_tabContainer);
            _tabContainer.x = 30;
            _tabContainer.y = BORDER_BLANKING;
            var tabXPos:int = 0;

            _openTab = createTab(tabXPos, _openMask, "打开");
            tabXPos += tabWidth + 7;
            _modelTab = createTab(tabXPos, _modelMask, "播放模式")
            tabXPos += tabWidth + 7;
            _scaleTab = createTab(tabXPos, _scaleMask, "画面比例")
        }

        public function css(styleProps:Object = null):Object {
            return {};
        }

        public function animate(styleProps:Object):Object {
            return {};
        }

        public function onBeforeCss(styleProps:Object = null):void {
        }

        public function onBeforeAnimate(styleProps:Object):void {
        }
    }
}
