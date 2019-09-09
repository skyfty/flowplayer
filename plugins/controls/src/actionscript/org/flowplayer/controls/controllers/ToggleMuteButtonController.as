/* * Author: Thomas Dubois, <thomas _at_ flowplayer org> * This file is part of Flowplayer, http://flowplayer.org * * Copyright (c) 2011 Flowplayer Ltd * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.controls.controllers {	import org.flowplayer.view.Flowplayer;	import org.flowplayer.model.PlayerEvent;	import org.flowplayer.model.PlayerEventType;		import org.flowplayer.ui.controllers.AbstractToggleButtonController;	import org.flowplayer.ui.buttons.ToggleButtonConfig;	import org.flowplayer.ui.buttons.ButtonEvent;	import org.flowplayer.ui.buttons.ToggleButton;		import org.flowplayer.controls.Controlbar;	import org.flowplayer.controls.SkinClasses;	import flash.display.DisplayObjectContainer;		public class ToggleMuteButtonController extends AbstractToggleButtonController {		public function ToggleMuteButtonController() {			super();		}				override public function get name():String {			return "mute";		}			override public function get defaults():Object {			return {				tooltipEnabled: true,				tooltipLabel: "音量",				visible: true,				enabled: true			};		}				override public function get downName():String {			return "unmute";		}				override public function get downDefaults():Object {			return {				tooltipEnabled: true,				tooltipLabel: "音量",				visible: true,				enabled: true			};		}			override protected function get faceClass():Class {			return SkinClasses.getClass("fp.MuteButton");		}				override protected function get downFaceClass():Class {			return SkinClasses.getClass("fp.UnMuteButton");		}				// mute related stuff		override protected function addPlayerListeners():void {			// we don't care about calling super 'cause we don't need to listen on play/pause stuff						_player.onMute(onPlayerMute);            _player.onUnmute(onPlayerMute);		}				protected function onPlayerMute(event:PlayerEvent):void {			isDown = event.eventType == PlayerEventType.MUTE;		}		override protected function onButtonClicked(event:ButtonEvent):void {            _player.muted = ! _player.muted;        }		override protected function setDefaultState():void {			isDown = _player.muted;		}	}}