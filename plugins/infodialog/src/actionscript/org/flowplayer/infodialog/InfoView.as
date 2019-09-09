package org.flowplayer.infodialog {
   
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.*;
	import org.flowplayer.model.DisplayPluginModel;	
	import org.flowplayer.ui.buttons.ButtonDecorator;
	import org.flowplayer.ui.buttons.ConfigurableWidget;
	import org.flowplayer.ui.buttons.ToggleButtonConfig;
	import org.flowplayer.ui.buttons.WidgetDecorator;
	import org.flowplayer.ui.controllers.AbstractButtonController;
	import org.flowplayer.ui.controllers.AbstractWidgetController;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.view.AbstractSprite;
	import org.flowplayer.view.Flowplayer;
	import org.flowplayer.view.StyleableSprite;
    import org.flowplayer.ui.buttons.ToggleButtonConfig;
    import org.flowplayer.ui.buttons.TooltipButtonConfig;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;	
    import org.flowplayer.model.Clip;
    import org.flowplayer.model.ClipEvent;
    import org.flowplayer.model.ClipEventType;
    import org.flowplayer.model.Playlist;

    public class InfoView extends StyleableView {

        private var _config:Config;
        private var _player:Flowplayer;
		
		// #71, need to have a filled sprite who takes all the space to get events to work
		private var _bgFill:Sprite;
        private var _textLabel:TextField;
        private var _returnWidget:AbstractWidgetController;

        public function InfoView(plugin:DisplayPluginModel, infoDialog:InfoDialog, player:Flowplayer, config:Config) {
        	super("viral-model", plugin, player, config.canvas);
			_player = player;
			_config = config;

			_bgFill = new Sprite();
			addChild(_bgFill);
 	
			_returnWidget = new ReturnButtonControler(infoDialog);
			var widgetConfig:Object = _config.getWidgetConfiguration(_returnWidget);
			_returnWidget.init(_player, this,widgetConfig);
			_returnWidget.configure(widgetConfig);
			addChild(_returnWidget.view);	

			this.visible = true;
        }


        private function createLabel(htmlText:String = null, parent:DisplayObject = null):TextField {
            var field:TextField = createLabelField();
            if (htmlText != null) {
                field.htmlText = htmlText;
            }
            (parent ? parent : this).addChild(field);
            return field;
        }
        
        public function set message(msg:String):void {
            if (_textLabel != null) {
                removeChild(_textLabel);
            }
            _textLabel = createLabel("<span class=\"label\">" +msg+ "</span>"); 
            addChild(_textLabel);           
        }

        override protected function onResize():void {

			_bgFill.graphics.clear();
			_bgFill.graphics.beginFill(0, 0);
			_bgFill.graphics.drawRect(0, 0, width, height);
			_bgFill.graphics.endFill();
			
			if (_textLabel) {
				Arrange.center(_textLabel, width, height);               
			}	
			
			if (_returnWidget) {
				_returnWidget.view.x = width - _returnWidget.view.width - 10;
				_returnWidget.view.y = height - _returnWidget.view.height - 10;
			}			
        }
    }
}
