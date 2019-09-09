/*    
 *    Copyright 2008 Anssi Piirainen
 *
 *    This file is part of FlowPlayer.
 *
 *    FlowPlayer is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    FlowPlayer is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with FlowPlayer.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.flowplayer.model {
	import org.flowplayer.model.ErrorCode;
	
	/**
	 * Clip error codes.
	 */
	public class ClipError extends ErrorCode {
		
		public static const STREAM_NOT_FOUND:ClipError = new ClipError(ClipEventType.ERROR, 200, "很抱歉，文件加载失败!");		
		public static const STREAM_LOAD_FAILED:ClipError = new ClipError(ClipEventType.ERROR, 201, "很抱歉，文件加载失败!");		
		public static const PROVIDER_NOT_LOADED:ClipError = new ClipError(ClipEventType.ERROR, 202, "很抱歉，文件加载失败!");		
        public static const STREAM_ERR_FORMAT:ClipError = new ClipError(ClipEventType.ERROR, 203, "文件格式错误，请重新加载！");		
        public static const STREAM_TIMEOUT:ClipError = new ClipError(ClipEventType.ERROR, 204, "网络过慢，请重新加载！");		
    	public static const SERVER_FAILED:ClipError = new ClipError(ClipEventType.ERROR, 205, "无法连接服务器， 请重试");		

		public function ClipError(eventType:EventType, code:int, message:String) {
			super(eventType, code, message);
		}
	}
}
