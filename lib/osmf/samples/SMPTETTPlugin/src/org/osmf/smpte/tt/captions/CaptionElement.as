/***********************************************************
 * 
 * Copyright 2011 Adobe Systems Incorporated. All Rights Reserved.
 *
 * *********************************************************
 * The contents of this file are subject to the Berkeley Software Distribution (BSD) Licence
 * (the "License"); you may not use this file except in
 * compliance with the License. 
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 *
 * The Initial Developer of the Original Code is Adobe Systems Incorporated.
 * Portions created by Adobe Systems Incorporated are Copyright (C) 2011 Adobe Systems
 * Incorporated. All Rights Reserved.
 **********************************************************/
package org.osmf.smpte.tt.captions
{
	/**
	 * 
	 * @author mjordan
	 * 
	 */
	public class CaptionElement extends TimedTextElement
	{
		/**
		 * 
		 * @param start
		 * @param end
		 * @param id
		 * 
		 */
		public function CaptionElement(start:Number, end:Number, id:String=null)
		{
			super(start, end, id);
			this.captionElementType = TimedTextElementType.Text;
		}
		
		private var _index:int;
		/**
		 * 
		 * @return 
		 * 
		 */
		public function get index():int
		{
			return _index;
		}
		/**
		 * 
		 * @param value
		 * 
		 */
		public function set index(value:int):void
		{
			_index = value;
		}
		
		private var _regionId:String;
		/**
		 * 
		 * @return 
		 * 
		 */
		public function get regionId():String
		{
			return _regionId;
		}
		/**
		 * 
		 * @param value
		 * 
		 */
		public function set regionId(value:String):void
		{
			_regionId = value;
		}

	}
}