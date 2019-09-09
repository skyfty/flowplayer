/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <support@flowplayer.org>
 *Copyright (c) 2008-2011 Flowplayer Oy *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */

package org.flowplayer.infodialog {
    
	import org.flowplayer.view.StyleableSprite;
	import org.flowplayer.view.Flowplayer;
	
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.DisplayPluginModel;
	
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.util.Arrange
	
	import org.flowplayer.ui.containers.WidgetContainer;
	import org.flowplayer.ui.containers.WidgetContainerEvent;
	
	import org.flowplayer.ui.controllers.AbstractWidgetController;
	
	import org.flowplayer.ui.AutoHide;
	import org.flowplayer.ui.AutoHideConfig;
	
	import org.flowplayer.infodialog.Config;
    import org.flowplayer.model.PluginEvent;
    import org.flowplayer.model.PluginModel;
	
	import flash.events.Event;
	import flash.system.Security;
	import flash.system.ApplicationDomain;
	
	import flash.utils.*;
    import flash.accessibility.Accessibility;

    /**
     * @author anssi
     */
    public class InfoDialog extends StyleableSprite implements Plugin {

        private var _config:Config;
        private var _player:Flowplayer;
        private var _pluginModel:PluginModel;
		private var _infoview:InfoView;
        private var _returnFunction : Function = null;
		
		public function onConfig(model:PluginModel):void {
            _pluginModel = model;
            _config = new PropertyBinder(new Config()).copyProperties(model.config) as Config;
        }

		public function onLoad(player:Flowplayer):void {
			// with older versions of FP we are called twice
			if ( _player )	return;
		
			_player = player;
            lookupPluginAndBindEvent(_player, "optionsdialog", onOptionModel);
            
            addPlayListListeners();
            
			_infoview = new InfoView(_pluginModel as DisplayPluginModel, this, _player, _config);
			addChild(_infoview);
	
			_pluginModel.dispatchOnLoad();
			this.visible = false;
		}
        
        private function onOptionModel(event:PluginEvent):void {
            log.debug("Timeout error has occured ");
            if (event.id=="onOptionModel") {
                this.visible = false;
            }
        }
        
        private function lookupPluginAndBindEvent(player:Flowplayer, pluginName:String, eventHandler:Function):void {
            var plugin:PluginModel = player.pluginRegistry.getPlugin(pluginName) as PluginModel;
            if (plugin) {
                log.debug("found plugin " +plugin);
                plugin.onPluginEvent(eventHandler);
            }
        }
        
        public function invoke():void {
            if (_returnFunction != null) {
                _returnFunction();
            }
        }
        
        private function addPlayListListeners():void {
            var playlist:Playlist =_player.playlist;
            playlist.onError(onClipError);
            playlist.onBegin(onBegin);
        }
        
        private function onBegin(event:ClipEvent):void {
            this.visible = false;
        }
        
        private function onClipError(event:ClipEvent):void {
            if (event.isDefaultPrevented()) return;
            _returnFunction = null;
            
            switch (event.error.code) {
                case 200:
                case 201: 
                case 202: 
                case 203:

                {
                    _returnFunction = function():void {
                        this.visible = false;
                        _player.close();
                    }
                    break;
                }
                case 204:
                case 205:
                case 500:
                {
                    _returnFunction = function():void {
                        _player.play();
                        this.visible = false;
                    }                   
                }
                break;
            }
            if (_returnFunction != null) {
                _infoview.message = event.error.message;
                _infoview.setSize(width, height);
                this.visible = true;                
            }
         }
        

        public function getDefaultConfig():Object {
            return SkinClasses.defaults;
        }

        override protected function onResize():void {
            if (! _infoview) return;
           _infoview.setSize(width, height);
        }
    }
}
