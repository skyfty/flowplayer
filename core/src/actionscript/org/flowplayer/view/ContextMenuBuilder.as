/*    
 *    Copyright 2008 Anssi Piirainen
 *
 *    This file is part of Flowplayer.
 *
 *    Flowplayer is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Flowplayer is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Flowplayer.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.flowplayer.view {
	import org.flowplayer.util.Log;	
	
	import flash.events.ContextMenuEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import org.flowplayer.config.VersionInfo;	

	/**
	 * @author api
	 */
	public class ContextMenuBuilder {
		private var log:Log = new Log(this);
		private var _menuItems:Array;
		private var _playerId:String;

		public function ContextMenuBuilder(playerId:String, menuItems:Array) {
			_playerId = playerId;
			_menuItems = menuItems;
		}
		
		public function build():ContextMenu { 
				return buildCustomMenu(createMenu(), _menuItems);
		}
	
		private function buildCustomMenu(menu:ContextMenu, menuItems:Array):ContextMenu {
			if (! menuItems) return menu;
			var separatorBeforeNextItem:Boolean = false;
			var itemNum:int = 0;
			for (var i:Number = 0; i < menuItems.length; i++) {
				var item:Object = menuItems[i];
				if (item is String && item == "-") {
					separatorBeforeNextItem = true;
                    itemNum++;
				} else if (item is String) {
					addCustomMenuItem(menu, item as String, itemNum++, null, separatorBeforeNextItem);
					separatorBeforeNextItem = false;
				} else {
					for (var label:String in item) {
						log.debug("creating menu item for " + label + ", callback " + item[label]);
						addCustomMenuItem(menu, label, itemNum++, item[label], separatorBeforeNextItem);
					}
					separatorBeforeNextItem = false;
				}
			}
			return menu;
		}
		
		private function addCustomMenuItem(menu:ContextMenu, label:String, itemIndex:int, callback:*, separatorBeforeNextItem:Boolean):void {
            if (! callback || callback == "null") {
				addItem(menu, new ContextMenuItem(label, separatorBeforeNextItem, false));
			} else if (callback is Object && Object(callback).hasOwnProperty("url")) {
                //Issue #384 added links support in context menus with configuration { url: "domain.com", target: "_blank"} which will work in embedded players.
                log.debug("creating item with link");
                addItem(menu, new ContextMenuItem(label, separatorBeforeNextItem, true), function(event:ContextMenuEvent):void {
                  navigateToURL(new URLRequest(callback.url), Object(callback).hasOwnProperty("target") ? Object(callback).target : "_self");
                });
            } else {
				log.debug("creating item with callback");
				addItem(menu, new ContextMenuItem(label, separatorBeforeNextItem, true), createCallback(itemIndex));
			}
		}

		private function createCallback(itemIndex:int):Function {
			return function(event:ContextMenuEvent):void {
				log.debug("in event handler, playerId " + _playerId);
				ExternalInterface.call(
				"flowplayer.fireEvent",
				_playerId || ExternalInterface.objectID, "onContextMenu", itemIndex);
			};
		}
	
		private function createMenu():ContextMenu {
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			return menu;
		}
		private function addItem(menu:ContextMenu, item:ContextMenuItem, selectHandler:Function = null):void {
			menu.customItems.push(item);
			if (selectHandler != null) {
				item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, selectHandler);
			}
		}
	}
}