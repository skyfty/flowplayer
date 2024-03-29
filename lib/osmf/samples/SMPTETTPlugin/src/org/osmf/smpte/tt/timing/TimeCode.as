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
package org.osmf.smpte.tt.timing
{
	import org.osmf.smpte.tt.enums.NumberType;
	import org.osmf.smpte.tt.utilities.StringUtils;
	
	/**
	 *  Represents a SMPTE 12M standard time code and provides conversion operations to various SMPTE time code formats and rates.
	 *  
	 *  Framerates supported by the TimeCode class include, 23.98 IVTC Film Sync, 24fps Film Sync, 25fps PAL, 29.97 drop frame,
	 *  29.97 Non drop, and 30fps.
	 */
	public class TimeCode
	{
		/**
		 * Regular expression string used for parsing out the timecode.
		 */
		public static const SMPTEREGEXSTRING:String = "^(?:(?P<Days>\d+):)?(?P<Hours>2[1-3]|[0-1]\d):(?P<Minutes>[0-5]\d]):(?P<Seconds>[0-5]\d)(?::|;)(?P<Frames>[0-2]\d)$";
		
		/**
		 *  Regular expression object used for validating timecode.
		 */
		public static const _validateTimecode:RegExp = /^(?:(?P<Days>\d+):)?(?P<Hours>2[1-3]|[0-1]\d):(?P<Minutes>[0-5]\d):(?P<Seconds>[0-5]\d)(?::|;)(?P<Frames>[0-2]\d)$/;
		
		private var _absoluteTime:AbsoluteTimeHelper;
		
		/**
		 * The frame rate for this instance.
		 */
		private var _frameRate:SmpteFrameRate;
		
		/**
		 * The TimeCode can be created from several different sets of parameters. 
		 * 
		 * <p>With 5 or 6 parameters, initializes a new instance of the TimeCode structure 
		 * to a specified number of days, hours, minutes, and seconds.</p>
		 * 
		 * @param days:int - Number of days. (optional)  
		 * @param hours:int - Number of hours. 
		 * @param minutes:int - Number of minutes. 
		 * @param seconds:int - Number of seconds. 
		 * @param frames:int - Number of frames. 
		 * @param rate:SmpteFrameRate - The SMPTE frame rate. 
		 * 
		 * <p>With 3 parameters, initializes a new instance of the TimeCode structure using 
		 * either an absolute time value or a value of a 27 Mhz clock, and the SMPTE framerate.</p>
		 * 
		 * @param absoluteTime:Number - The double that represents the absolute time value.
		 *   or
		 * @param ticks27Mhz:Number - The long value in 27 Mhz clock ticks.
         * @param rate:SmpteFrameRate - The SMPTE framerate that this instance should use.
		 * @param numberType:NumberType - The datatype of the first parameter NumberType.DOUBLE for absoluteTime or NumberType.Long for ticks27Mhz.
		 * 
		 * <p>With 2 parameters, initializes a new instance of the TimeCode structure using 
		 * either the totalSeconds of a TimeSpan object or an SMPTE 12m time code string, 
		 * and either an SMPTE framerate or a decimal rate.</p>
		 * 
		 * @param timeSpan:TimeSpan - The TimeSpan to be used for the new timecode..
		 *   or
		 * @param timeCode:String - The SMPTE 12m time code string.
		 *  and
         * @param rate:SmpteFrameRate - The SMPTE framerate that this instance should use.
		 *  or
		 * @param rate:Number - The Smpte frame rate.
		 * 
		 * <p>With 1 parameter, initializes a new instance of the TimeCode structure 
		 * using a time code string that contains the framerate at the end of the string.</p>
		 * 
		 * <p>Pass in a timecode in the format "timecode@framrate". 
		 * Supported rates include @23.98, @24, @25, @29.97, @30</p>
         * 
		 * <p>For example: <br/>
         * "00:01:00:00@29.97" is equivalent to 29.97 non drop frame.<br/>
         * "00:01:00;00@29.97" is equivalent to 29.97 drop frame.</p>
		 * 
		 * @param timeCodeAndRate:String - The SMPTE 12m time code string.
		 */
		public function TimeCode(...args:*)
		{
			var len:uint = args.length,
				days:Number,
				hours:Number,
				minutes:Number,
				seconds:Number,
				frames:Number,
				timeCode:String="",
				i:uint;
			switch(len){
				case 6:
				case 5:
					var actualRate:Number;
					if(args[(len-1)] is SmpteFrameRate){
						this.frameRate = args[(len-1)];
						for(i=0; i<(len-1); i++){
							if(args[i] is int){
								timeCode += (i==0 && len==6) ? args[i] : TimeCode.twoDigits(args[i]);
								if(i<len-2){
									timeCode += ":";
								}
							} else 
							{
								throw new Error("Invalid TimeCode input. Parameter "+i+" ( "+ args[i] + " ) must be an integer.");
							}
						}
						this._absoluteTime = TimeCode.smpte12mToAbsoluteTime(timeCode, this.frameRate);	
					} else if(len == 6 && args[5] is Number)
					{
						actualRate = args[5];
						this.frameRate = TimeCode.parseFramerate(actualRate);
						if (args[1] > 23) throw new Error("hours cannot be greater than 23");
						if (args[2] > 59) throw new Error("minutes cannot be greater than 59");
						if (args[3] > 59) throw new Error("seconds cannot be greater than 59");
						if (args[4] >= actualRate) throw new Error("frames cannot be greater than rate");
						days = args[0];
						hours = args[1];
						minutes = args[2];
						seconds = args[3];
						frames = args[4];
						if(this.frameRate!=SmpteFrameRate.UNKNOWN)
						{
							for(i=0; i<(len-1); i++){
								if(args[i] is int){
									timeCode += (i==0 && len==6) ? args[i] : TimeCode.twoDigits(args[i]);
									if(i<len-2){
										timeCode += ":";
									}
								} else 
								{
									throw new Error("Invalid TimeCode input. Parameter "+i+" ( "+ args[i] + " ) must be an integer.");
								}
							}
							this._absoluteTime = TimeCode.smpte12mToAbsoluteTime(timeCode, this.frameRate);
						} else
						{
							this._absoluteTime = new AbsoluteTimeHelper((1 / actualRate) * frames + seconds + (60 * minutes) + (3600 * hours) + (86400 * days),NumberType.DOUBLE);
						}
					} else if(len == 5 && args[4] is Number)
					{
						actualRate = args[4];
						this.frameRate = TimeCode.parseFramerate(actualRate);
						if (args[0] > 23) throw new Error("hours cannot be greater than 23"); 
						if (args[1] > 59)throw new Error("minutes cannot be greater than 59");
						if (args[2] > 59) throw new Error("seconds cannot be greater than 59");
						if (args[3] >= actualRate) throw new Error("frames cannot be greater than rate");
						hours = args[0];
						minutes = args[1];
						seconds = args[2];
						frames = args[3];
						if(this.frameRate!=SmpteFrameRate.UNKNOWN)
						{
							for(i=0; i<(len-1); i++){
								if(args[i] is int){
									timeCode += (i==0 && len==6) ? args[i] : TimeCode.twoDigits(args[i]);
									if(i<len-2){
										timeCode += ":";
									}
								} else 
								{
									throw new Error("Invalid TimeCode input. Parameter "+i+" ( "+ args[i] + " ) must be an integer.");
								}
							}
							this._absoluteTime = TimeCode.smpte12mToAbsoluteTime(timeCode, this.frameRate);
						} else
						{	
							this._absoluteTime = new AbsoluteTimeHelper((1 / actualRate) * frames + seconds + (60 * minutes) + (3600 * hours),NumberType.DOUBLE);
						}
					} else {
						throw new Error("Parameters do not seem to combine to form a valid TimeCode: ["+args.toString()+"]");
					}
					break;
				case 3:
					if(args[0] is Number 
						&& args[1] is SmpteFrameRate 
						&& args[2] is NumberType){
						this.frameRate =  args[1];
						this._absoluteTime = new AbsoluteTimeHelper(args[0],args[2]);
					} else {
						throw new Error("Parameters do not seem to combine to form a valid TimeCode: ["+args.toString()+"]");
					}
					break;
				case 2:
					if(args[1] is SmpteFrameRate){
						this.frameRate =  args[1];
						if(args[0] is TimeSpan){
							this._absoluteTime = TimeCode.fromTimeSpan(args[0], this.frameRate).absoluteTime;
						} else if(args[0] is String){
							this._absoluteTime = TimeCode.smpte12mToAbsoluteTime(args[0], this.frameRate);
						}
					} else if(args[0] is TimeSpan 
						&& args[1] is Number) {
						this.frameRate = TimeCode.parseFramerate(args[1]);
						this._absoluteTime = new AbsoluteTimeHelper((args[0] as TimeSpan).totalSeconds, NumberType.DOUBLE);
					} else {
						throw new Error("Parameters do not seem to combine to form a valid TimeCode: ["+args.toString()+"]");
					}
					break;
				case 1:
					var timeAndRate:Array = args[0].split("@");
					
					var time:String = '';
					var rate:String = '';
					
					if (timeAndRate.length == 1)
					{
						time = timeAndRate[0];
						rate = "29.97";
					}
					else if (timeAndRate.length == 2)
					{
						time = timeAndRate[0];
						rate = timeAndRate[1];
					}
					
					this.frameRate = SmpteFrameRate.SMPTE_2997_NONDROP;
					
					if (rate == "29.97" && time.indexOf(';') > -1)
					{
						this.frameRate = SmpteFrameRate.SMPTE_2997_DROP;
					}
					else if (rate == "29.97" && time.indexOf(';') == -1)
					{
						this.frameRate = SmpteFrameRate.SMPTE_2997_NONDROP;
					}
					else if (rate == "25")
					{
						this.frameRate = SmpteFrameRate.SMPTE_25;
					}
					else if (rate == "23.98")
					{
						this.frameRate = SmpteFrameRate.SMPTE_2398;
					}
					else if (rate == "24")
					{
						this.frameRate = SmpteFrameRate.SMPTE_24;
					}
					else if (rate == "30")
					{
						this.frameRate = SmpteFrameRate.SMPTE_30;
					}
					
					this._absoluteTime = TimeCode.smpte12mToAbsoluteTime(time, this.frameRate);
					break;
			}
			// trace("new TimeCode("+args.toString()+") \n\t{ time27Mhz: "+absoluteTime.time27Mhz+", timeAsFloat: "+absoluteTime.timeAsFloat+", pcrTime: "+absoluteTime.pcrTime+" }\n");
		}
		
		/**
		 *  Convert an integer value into two digits.
		 */
		private static function twoDigits(p_value:int):String
		{
			var result:Array = [];
			result[0] = ((p_value / 10) + int('0')).toString(16);
			result[1] = ((p_value % 10) + int('0')).toString(16);
			return result.join('');
		}
		
		
		/**
		 * The number of milliseconds in one day
		 */     
		public static const MILLISECONDS_PER_DAY:Number = 86400000;
		
		/**
		 * The number of milliseconds in one hour
		 */     
		public static const MILLISECONDS_PER_HOUR:Number = 3600000;
		
		/**
		 * The number of milliseconds in one minute
		 */     
		public static const MILLISECONDS_PER_MINUTE:Number = 60000;
		
		/**
		 * The number of milliseconds in one second
		 */     
		public static const MILLISECONDS_PER_SECOND:Number = 1000;
		
		/**
		 * The number of ticks in one millisecond
		 */ 
		public static const TICKS_PER_MILLISECOND:Number = 10000;
		
		/**
		 * The number of absolute time ticks in 1 millisecond. This field is constant.
		 */ 
		public static const TICKS_PER_MILLISECOND_ABSOLUTE_TIME:Number = 0.001;
		
		/**
		 * The number of ticks in one second
		 */
		public static const TICKS_PER_SECOND:Number = 10000000;
		
		/**
		 * The number of absolute time ticks in one second
		 */
		public static const TICKS_PER_SECOND_ABSOLUTE_TIME:Number = 1;
		
		/**
		 * The number of ticks in one minute
		 */
		public static const TICKS_PER_MINUTE:Number = 600000000;
		
		/**
		 * The number of absolute time ticks in one minute
		 */
		public static const TICKS_PER_MINUTE_ABSOLUTE_TIME:Number = 60;
		
		/**
		 * The number of ticks in one hour
		 */
		public static const TICKS_PER_HOUR:Number = 36000000000;
		
		/**
		 * The number of absolute time ticks in 1 hour.
		 */
		public static const TICKS_PER_HOUR_ABSOLUTE_TIME:Number = 3600;
		
		/**
		 * The number of ticks in one day
		 */
		public static const TICKS_PER_DAY:Number = 864000000000;
		
		/**
		 * The number of absolute time ticks in 1 day.
		 */
		public static const TICKS_PER_DAY_ABSOLUTE_TIME:Number = 86400;
		
		/**
		 * The minimum TimeCode value. This field is read-only.
		 */
		public static const MIN_VALUE:Number = 0;
		
		/**
		 * Gets the absolute time in seconds of the current TimeCode object.
		 */
		public function get duration():Number
		{
			return this.absoluteTime.timeAsDouble;
		}
		
		/**
		 * Gets or sets the current SMPTE framerate for this TimeCode instance.
		 */
		public function get frameRate():SmpteFrameRate
		{
			return _frameRate;
		}
		public function set frameRate(p_frameRate:SmpteFrameRate):void
		{
			_frameRate = p_frameRate;
		}
		
		/**
		 * Gets the number of whole hours represented by the current TimeCode structure.
		 * 
		 * @returns The hour component of the current TimeCode structure. The return value ranges from 0 through 23.
		 */
		public function get hoursSegment():int
		{
			var timeCode:String = TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, this.frameRate);
			var hours:String = timeCode.substring(0, 2);
			return parseInt(hours);
		}
		
		/**
		 * Gets the number of whole minutes represented by the current TimeCode structure.
		 * 
		 * @returns The minute component of the current TimeCode structure. The return value ranges from 0 through 59.
		 */
		public function get minutesSegment():int
		{
			var timeCode:String = TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, this.frameRate);
			var minutes:String = timeCode.substring(3, 2);
			return parseInt(minutes);
		}
		
		/**
		 * Gets the number of whole seconds represented by the current TimeCode structure.
		 * 
		 * @returns The seconds component of the current TimeCode structure. The return value ranges from 0 through 59.
		 */
		public function get secondsSegment():int
		{
			var timeCode:String = TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, this.frameRate);
			var seconds:String = timeCode.substring(6, 2);
			return parseInt(seconds);
		}
		
		/**
		 * Gets the number of whole frames represented by the current TimeCode structure.
		 * 
		 * @returns The frame component of the current TimeCode structure. The return value depends on the framerate selected for this instance. All frame counts start at zero.
		 */
		public function get framesSegment():int
		{
			var timeCode:String = TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, this.frameRate);
			var frames:String = timeCode.substring(9, 2);
			return parseInt(frames);
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in whole and fractional days.
		 *
		 * @returns The total number of days represented by this instance.
		 */  
		public function get totalDays():Number
		{
			var framecount:Number = TimeCode.absoluteTimeToFrames(this.absoluteTime, this.frameRate);
			return (framecount / 108000) / 24;
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in whole
		 *  and fractional hours.
		 *
		 * @returns The total number of hours represented by this instance.
		 */ 
		public function get totalHours():Number
		{
			var framecount:Number = TimeCode.absoluteTimeToFrames(this.absoluteTime, this.frameRate);
			
			var hours:Number;
			
			switch (this.frameRate)
			{
				case SmpteFrameRate.SMPTE_2398:
				case SmpteFrameRate.SMPTE_24:
					hours = framecount / 86400;
					break;
				case SmpteFrameRate.SMPTE_25:
					hours = framecount / 90000;
					break;
				case SmpteFrameRate.SMPTE_2997_DROP:
					hours = framecount / 107892;
					break;
				case SmpteFrameRate.SMPTE_2997_NONDROP:
				case SmpteFrameRate.SMPTE_30:
					hours = framecount / 108000;
					break;
				default:
					hours = framecount / 108000;
					break;
			}
			
			return hours;
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in whole
		 *  and fractional minutes.
		 *
		 * @returns The total number of minutes represented by this instance.
		 */  
		public function get totalMinutes():Number
		{
			
			var framecount:Number = TimeCode.absoluteTimeToFrames(this.absoluteTime, this.frameRate);
			
			var minutes:Number;
			
			switch (this.frameRate)
			{
				case SmpteFrameRate.SMPTE_2398:
				case SmpteFrameRate.SMPTE_24:
					minutes = framecount / 1400;
					break;
				case SmpteFrameRate.SMPTE_25:
					minutes = framecount / 1500;
					break;
				case SmpteFrameRate.SMPTE_2997_DROP:
				case SmpteFrameRate.SMPTE_2997_NONDROP:
				case SmpteFrameRate.SMPTE_30:
					minutes = framecount / 1800;
					break;
				default:
					minutes = framecount / 1800;
					break;
			}
			
			return minutes;
			
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in whole
		 *  and fractional seconds. Not as Precise as the TotalSecondsPrecision.
		 *
		 * @returns The total number of seconds represented by this instance.
		 */  
		public function get totalSeconds():Number
		{
			return this.absoluteTime.timeAsDouble;
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in whole
		 *  and fractional seconds. This is returned as a <see cref="decimal"/> for greater precision.
		 *
		 * @returns The total number of seconds represented by this instance.
		 */  
		public function get totalSecondsPrecision():Number
		{
			return this.absoluteTime.timeAsFloat;
		}
		
		/**
		 * Gets the value of the current TimeCode structure expressed in frames.
		 *
		 * @returns The total number of frames represented by this instance.
		 */  
		public function get totalFrames():Number
		{
			return TimeCode.absoluteTimeToFrames(this.absoluteTime, this.frameRate);
		}
	
		/**
		 * The private Timespan used to track absolute time for this instance.
		 */
		private function get absoluteTime():AbsoluteTimeHelper
		{
			if (_absoluteTime == null)
			{
				_absoluteTime = new AbsoluteTimeHelper(0);
			}
			
			return _absoluteTime;
		}
		private function set absoluteTime(p_absoluteTime:AbsoluteTimeHelper):void
		{	
			_absoluteTime = p_absoluteTime;
		}
		
		/**
		 * Returns a SMPTE 12M formatted time code string from a 27Mhz ticks value.
		 * 
		 * @param ticks27Mhz 27Mhz ticks value.
		 * @param rate The SMPTE time code framerate desired.
		 * @returns A SMPTE 12M formatted time code string.
		 */
		public static function ticks27MhzToSmpte12M(ticks27Mhz:Number, rate:SmpteFrameRate):String
		{
			var s:String = TimeCode.ticks27MhzToSmpte12M_30fps(ticks27Mhz);
			switch (rate)
			{
				case SmpteFrameRate.SMPTE_2398:
					s = TimeCode.ticks27MhzToSmpte12M_23_98fps(ticks27Mhz);
					break;
				case SmpteFrameRate.SMPTE_24:
					s = TimeCode.ticks27MhzToSmpte12M_24fps(ticks27Mhz);
					break;
				case SmpteFrameRate.SMPTE_25:
					s = TimeCode.ticks27MhzToSmpte12M_25fps(ticks27Mhz);
					break;
				case SmpteFrameRate.SMPTE_2997_DROP:
					s = TimeCode.ticks27MhzToSmpte12M_29_27_Drop(ticks27Mhz);
					break;
				case SmpteFrameRate.SMPTE_2997_NONDROP:
					s = TimeCode.ticks27MhzToSmpte12M_29_27_NonDrop(ticks27Mhz);
					break;
				case SmpteFrameRate.SMPTE_30:
					s = TimeCode.ticks27MhzToSmpte12M_30fps(ticks27Mhz);
					break;
				default:
					s = TimeCode.ticks27MhzToSmpte12M_30fps(ticks27Mhz);
					break;
			}
			return s;
		}
		
		/**
		 * Subtracts a specified TimeCode from this TimeCode.
		 *  
		 * @param t2 The TimeCode to subtract.
		 * 
		 * @returns A TimeCode whose value is the result of the value of this minus the value of t2.
		 */
		public function minus(t2:TimeCode):TimeCode
		{
			
			var frames:Number = this.totalFrames - t2.totalFrames;
			var t3:TimeCode = TimeCode.fromFrames(frames, this.frameRate);
			
			if (t3.totalSecondsPrecision < TimeCode.MIN_VALUE)
			{
				throw new Error("MinValueSmpte12MOverflowException");
			}
			
			return t3;
		}
		
		/**
		 * Adds a specified TimeCode to this TimeCode.
		 *  
		 * @param t2 The TimeCode to add.
		 * 
		 * @returns A TimeCode whose value is the result of the value of this plus the value of t2.
		 */
		public function plus(t2:TimeCode):TimeCode
		{
			var frames:Number = this.totalFrames + t2.totalFrames;
			var t3:TimeCode = TimeCode.fromFrames(frames, this.frameRate);
			
			return t3;
		}
		
		/**
		 * Indicates whether this TimeCode is less than another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is less than the value of t2; otherwise, false.
		 */
		public function lessThan(t2:TimeCode):Boolean
		{
			if(TimeCode.Compare(this,t2)==-1)
			{
				return true;
			}
			return false;
		}
		
		/**
		 * Indicates whether this TimeCode is less than or equal to another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is less than or equal to the value of t2; otherwise, false.
		 */
		public function lessThanOrEqualTo(t2:TimeCode):Boolean
		{
			var compare:int = TimeCode.Compare(this,t2);
			if(compare==-1 || compare==0)
			{
				return true;
			}
			return false;
		}
		
		/**
		 * Indicates whether this TimeCode is not equal to another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is not equal to the value of t2; otherwise, false.
		 */
		public function notEqualTo(t2:TimeCode):Boolean
		{
			return !this.equalTo(t2);
		}
		
		/**
		 * Indicates whether this TimeCode is equal to another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is equal to the value of t2; otherwise, false.
		 */
		public function equalTo(t2:TimeCode):Boolean
		{
			if(TimeCode.Compare(this,t2)==0)
			{
				return true;
			}
			return false;
		}
		
		/**
		 * Indicates whether this TimeCode equals another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this equals the value of t2; otherwise, false.
		 */
		public function equals(t2:Object):Boolean
		{
			if (!(t2 is TimeCode))
			{
				throw new ArgumentError("Object to compare must be a TimeCode");
			}
			return this.equalTo(t2 as TimeCode);
		}
		
		/**
		 * Indicates whether this TimeCode is greater than or equal to another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is greater than or equal to the value of t2; otherwise, false.
		 */
		public function greaterThanOrEqualTo(t2:TimeCode):Boolean
		{
			var compare:int = TimeCode.Compare(this,t2);
			if(compare==1 || compare==0)
			{
				return true;
			}
			return false;
		}
		
		/**
		 * Indicates whether this TimeCode is greater than another given TimeCode.
		 *  
		 * @param t2 The TimeCode to compare.
		 * 
		 * @returns true if the value of this is greater than the value of t2; otherwise, false.
		 */
		public function greaterThan(t2:TimeCode):Boolean
		{
			if(TimeCode.Compare(this,t2)==1)
			{
				return true;
			}
			return false;
		}
		
		/**
		 * Compares two TimeCode values and returns an integer that indicates their relationship.
		 * 
		 * @param t1 The first TimeCode.
		 * @param t2 The second TimeCode.
		 * 
		 * @returns Value Condition -1 t1 is less than t2, 0 t1 is equal to t2, 1 t1 is greater than t2.
		 */
		public static function Compare(t1:TimeCode,t2:TimeCode):int
		{
			// trace("Compare: "+t1.absoluteTime.timeAsDouble +" to "+ t2.absoluteTime.timeAsDouble);
			var timeCode1:TimeCode = new TimeCode(t1.absoluteTime.timeAsDouble, SmpteFrameRate.SMPTE_30, NumberType.DOUBLE);
			var timeCode2:TimeCode = new TimeCode(t2.absoluteTime.timeAsDouble, SmpteFrameRate.SMPTE_30, NumberType.DOUBLE);
			
			if (timeCode1.totalFrames < timeCode2.totalFrames)
			{
				return -1;
			} else if(timeCode1.totalFrames == timeCode2.totalFrames){
				return 0;
			}
			
			return 1;
		}
		
		/**
		 * Returns a value indicating whether two specified instances of TimeCode
		 *  are equal.
		 * 
		 * @param t1 The first TimeCode.
		 * @param t2 The second TimeCode.
		 * 
		 * @returns true if the values of t1 and t2 are equal; otherwise, false.
		 */
		public static function Equals(t1:TimeCode,t2:TimeCode):Boolean
		{
			return t1.equals(t2);
		}
		
		/**
		 * Returns a TimeCode that represents a specified number of days, where the specification is accurate to the nearest millisecond.
		 * 
		 * @param value A number of days accurate to the nearest millisecond.
		 * @param rate The desired SmpteFrameRate framerate for this instance.
		 * @returns A TimeCode that represents value.
		 */
		public static function fromDays(value:Number, rate:SmpteFrameRate):TimeCode
		{
			var absoluteTime:Number = value * TimeCode.TICKS_PER_DAY_ABSOLUTE_TIME;
			return new TimeCode(absoluteTime, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified number of hours, where the specification is accurate to the nearest millisecond.
		 * 
		 * @param value A number of hours accurate to the nearest millisecond.
		 * @param rate The desired SmpteFrameRate framerate for this instance.
		 * @returns A TimeCode that represents value.
		 */
		public static function fromHours(value:Number, rate:SmpteFrameRate):TimeCode
		{
			var absoluteTime:Number = value * TimeCode.TICKS_PER_HOUR_ABSOLUTE_TIME;
			return new TimeCode(absoluteTime, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified number of minutes, where the specification is accurate to the nearest millisecond.
		 * 
		 * @param value A number of minutes accurate to the nearest millisecond.
		 * @param rate The desired SmpteFrameRate framerate for this instance.
		 * @returns A TimeCode that represents value.
		 */
		public static function fromMinutes(value:Number, rate:SmpteFrameRate):TimeCode
		{
			var absoluteTime:Number = value * TimeCode.TICKS_PER_MINUTE_ABSOLUTE_TIME;
			return new TimeCode(absoluteTime, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified number of seconds, where the specification is accurate to the nearest millisecond.
		 * 
		 * @param value A number of seconds accurate to the nearest millisecond.
		 * @param rate The desired SmpteFrameRate framerate for this instance.
		 * @returns A TimeCode that represents value.
		 */
		public static function fromSeconds(value:Number, rate:SmpteFrameRate):TimeCode
		{
			var absoluteTime:Number = value * TimeCode.TICKS_PER_SECOND_ABSOLUTE_TIME;
			return new TimeCode(absoluteTime, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified number of frames.
		 * 
		 * @param value A number of frames.
		 * @param rate The framerate of the Timecode.
		 * @returns A TimeCode that represents value.
		 */
		public static function fromFrames(value:Number, rate:SmpteFrameRate):TimeCode
		{
			var ticks27Mhz:Number = TimeCode.framesToTicks27Mhz(value, rate);
			return new TimeCode(ticks27Mhz, rate, NumberType.ULONG);
		}
		
		/**
		 * Returns a TimeCode that represents a specified time, where the specification is in units of ticks.
		 * 
		 * @param ticks A number of ticks that represent a time.
		 * @param rate The Smpte framerate.
		 * @returns A TimeCode with a value of value.
		 */
		public static function fromTicks(ticks:Number, rate:SmpteFrameRate):TimeCode
		{
			var absoluteTime:Number = Math.pow(10, -7) * ticks;
			return new TimeCode(absoluteTime, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified time, where the specification is in units of 27 Mhz clock ticks.
		 * 
		 * @param value A number of ticks in 27 Mhz clock format.
		 * @param rate A Smpte framerate.
		 * @returns A TimeCode.
		 */
		public static function fromTicks27Mhz(value:Number, rate:SmpteFrameRate):TimeCode
		{
			return new TimeCode(value, rate, NumberType.ULONG);
		}
		
		/**
		 * Returns a TimeCode that represents a specified time, where the specification is in units of absolute time.
		 * 
		 * @param value The absolute time in 100 nanosecond units.
		 * @param rate The SMPTE framerate.
		 * @returnss A TimeCode.
		 */
		public static function fromAbsoluteTime(value:Number, rate:SmpteFrameRate):TimeCode
		{
			return new TimeCode(value, rate, NumberType.DOUBLE);
		}
		
		/**
		 * Returns a TimeCode that represents a specified time, where the specification is in units of absolute time.
		 *
		 * @param value The TimeSpan object.
		 * @param rate The SMPTE framerate.
		 * @returnss A TimeCode.
		 */
		public static function fromTimeSpan(value:TimeSpan, rate:SmpteFrameRate):TimeCode
		{
			return new TimeCode(value.totalSeconds, rate);
		}
		
		/**
		 * Validates that the string provided is in the correct format for SMPTE 12M time code.
		 * 
		 * @param timeCode String that is the time code.
		 * @returns True if this is a valid SMPTE 12M time code string.
		 */
		public static function validateSmpte12MTimecode(timeCode:String):Boolean
		{
			return TimeCode._validateTimecode.test(timeCode);
		}
		
		/**
		 * Returns the value of the provided time code string and framerate in 27Mhz ticks.
		 * 
		 * @param timeCode The SMPTE 12M formatted time code string.
		 * @param rate The SMPTE framerate.
		 * @returns A number that represents the value of the time code in 27Mhz ticks.
		 */
		public static function smpte12MToTicks27Mhz(timeCode:String, rate:SmpteFrameRate):Number
		{
			var t:Number = TimeCode.smpte12M_30fpsToTicks27Mhz(timeCode);
			switch (rate)
			{
				case SmpteFrameRate.SMPTE_2398:
					t = TimeCode.smpte12M_23_98fpsToTicks27Mhz(timeCode);
					break;
				case SmpteFrameRate.SMPTE_24:
					t = TimeCode.smpte12M_24fpsToTicks27Mhz(timeCode);
					break;
				case SmpteFrameRate.SMPTE_25:
					t = TimeCode.smpte12M_25fpsToTicks27Mhz(timeCode);
					break;
				case SmpteFrameRate.SMPTE_2997_DROP:
					t = TimeCode.smpte12M_29_27_DropToTicks27Mhz(timeCode);
					break;
				case SmpteFrameRate.SMPTE_2997_NONDROP:
					t = TimeCode.smpte12M_29_27_NonDropToTicks27Mhz(timeCode);
					break;
				case SmpteFrameRate.SMPTE_30:
					t = TimeCode.smpte12M_30fpsToTicks27Mhz(timeCode);
					break;
				default:
					t = TimeCode.smpte12M_30fpsToTicks27Mhz(timeCode);
					break;
			}
			return t;
		}
		
		/**
		 * Parses a framerate value as double and converts it to a member of the SmpteFrameRate enumeration.
		 * 
		 * @param rate Double value of the framerate.
		 * @returns A SmpteFrameRate enumeration value that matches the incoming rates.
		 */
		public static function parseFramerate(rate:Number):SmpteFrameRate
		{
			var rateRounded:int = Math.floor(rate);
			var s:SmpteFrameRate = SmpteFrameRate.UNKNOWN
			switch (rateRounded)
			{
				case 23: s = SmpteFrameRate.SMPTE_2398;
					break;
				case 24: s = SmpteFrameRate.SMPTE_24;
					break;
				case 25: s = SmpteFrameRate.SMPTE_25;
					break;
				case 29: s = SmpteFrameRate.SMPTE_2997_NONDROP;
					break;
				case 30: s = SmpteFrameRate.SMPTE_30;
					break;
				case 50: s = SmpteFrameRate.SMPTE_25;
					break;
				case 60: s = SmpteFrameRate.SMPTE_30;
					break;
				case 59: s = SmpteFrameRate.SMPTE_2997_NONDROP;
					break;
			}
			
			return s;
		}
		
		/**
		 * Adds the specified TimeCode to this instance.
		 * 
		 * @param ts A TimeCode.
		 * @returns A TimeCode that represents the value of this instance plus the value of ts.
		 */
		public function add(ts:TimeCode):TimeCode
		{
			return this.plus(ts);
		}
		
		/**
		 * Compares this instance to a specified object and returns an indication of their relative values.
		 * 
		 * @param value An object to compare, or null.
		 * @returns Value Condition -1 The value of this instance is less than the value of value. 0 The value of this instance is equal to the value of value. 1 The value of this instance is greater than the value of value.-or- value is null.
		 */
		public function compareTo(value:Object):int
		{
			if (!(value is TimeCode))
			{
				throw new Error("Object to compare must be a TimeCode");
			}
			
			var t1:TimeCode = value as TimeCode;
			
			return TimeCode.Compare(this,t1);
		}
		
		/**
		 * Subtracts the specified TimeCode from this instance.
		 * 
		 * @param ts A TimeCode.
		 * @returns A TimeCode whose value is the result of the value of this instance minus the value of ts.
		 */
		public function subtract(ts:TimeCode):TimeCode
		{
			return this.minus(ts);
		}
		
		/**
		 * Returns the SMPTE 12M string representation of the value of this instance.
		 * 
		 *  @returns A string that represents the value of this instance. The return value is
		 *      of the form: hh:mm:ss:ff for non-drop frame and hh:mm:ss;ff for drop frame code
		 *      with "hh" hours, ranging from 0 to 23, "mm" minutes
		 *      ranging from 0 to 59, "ss" seconds ranging from 0 to 59, and  "ff"  based on the 
		 *      chosen framerate to be used by the time code instance.
		 */
		public function toString():String
		{
			return TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, this.frameRate);
		}
		
		/**
		 * Returns the SMPTE 12M string representation of the value of this instance.
		 * 
		 *  @returns A string that represents the value of this instance. The return value is
		 *      of the form: hh:mm:ss:ff for non-drop frame and hh:mm:ss;ff for drop frame code
		 *      with "hh" hours, ranging from 0 to 23, "mm" minutes
		 *      ranging from 0 to 59, "ss" seconds ranging from 0 to 59, and  "ff"  based on the 
		 *      chosen framerate to be used by the time code instance.
		 */
		public function toStringAtFramerate(rate:SmpteFrameRate=null):String
		{
			return TimeCode.absoluteTimeToSmpte12M(this.absoluteTime, ((rate!=null) ? rate : this.frameRate));
		}
		
		/**
		 * Returns the value of this instance in 27 Mhz ticks.
		 * 
		 *  @returns A ulong value that is in 27 Mhz ticks.
		 */
		public function toTicks27Mhz():Number
		{
			return TimeCode.absoluteTimeToTicks27Mhz(this.absoluteTime);
		}
		
		/**
		 * Returns the value of this instance in MPEG 2 PCR time base (PcrTb) format.
		 * 
		 * @returns A Number value that is in PcrTb.
		 */
		public function toTicksPcrTb():Number
		{
			return TimeCode.absoluteTimeToTicksPcrTb(this.absoluteTime);
		}
		
		/**
		 * Converts a SMPTE timecode to absolute time.
		 * 
		 * @param timeCodeThe timecode to convert from.
		 * @param rate The SmpteFrameRate of the timecode.
		 * @returns An AbsoluteTimeHelper with the absolute time.
		 */
		private static function smpte12mToAbsoluteTime(timeCode:String, rate:SmpteFrameRate):AbsoluteTimeHelper
		{
			var ath:AbsoluteTimeHelper = new AbsoluteTimeHelper(0);
			
			switch (rate)
			{
				case SmpteFrameRate.SMPTE_2398:
					ath = TimeCode.smpte12M_23_98_ToAbsoluteTime(timeCode);
					break;
				case SmpteFrameRate.SMPTE_24:
					ath = TimeCode.smpte12M_24_ToAbsoluteTime(timeCode);
					break;
				case SmpteFrameRate.SMPTE_25:
					ath = TimeCode.smpte12M_25_ToAbsoluteTime(timeCode);
					break;
				case SmpteFrameRate.SMPTE_2997_DROP:
					ath = TimeCode.smpte12M_29_97_Drop_ToAbsoluteTime(timeCode);
					break;
				case SmpteFrameRate.SMPTE_2997_NONDROP:
					ath = TimeCode.smpte12M_29_97_NonDrop_ToAbsoluteTime(timeCode);
					break;
				case SmpteFrameRate.SMPTE_30:
					ath = TimeCode.smpte12M_30_ToAbsoluteTime(timeCode);
					break;
			}
			
			return ath;
		}
		
		/**
		 * Parses a timecode string for the different parts of the timecode.
		 * 
		 * 	@param timeCode The source timecode to parse.
		 */
		private static function parseTimecodeString(timeCode:String):TimeCodeComponents
		{
			if (!TimeCode.validateSmpte12MTimecode(timeCode))
			{
				throw new Error(timeCode+" is not a valid SMPTE 12M timecode");
			}
			var out:TimeCodeComponents = new TimeCodeComponents();
			out.days = 0;
			
			var times:Array = timeCode.match(TimeCode._validateTimecode);
			
			if (times.Days!=null)
			{
				out.days = parseInt(times.Days,10);
			}
			
			out.hours =  parseInt(times.Hours,10);
			out.minutes =  parseInt(times.Minutes,10);
			out.seconds =  parseInt(times.Seconds,10);
			out.frames = parseInt(times.Frames,10);
			
			return out;
		}
		
		/**
		 * Generates a string representation of the timecode.
		 *
		 * @param days The Days section from the timecode.
		 * @param hours The Hours section from the timecode.
		 * @param minutes The Minutes section from the timecode.
		 * @param seconds The Seconds section from the timecode.
		 * @param frames The frames section from the timecode.
		 * @param dropFrame Indicates whether the timecode is drop frame or not.
		 * @returns The timecode in string format.
		 */
		private static function formatTimeCodeString(days:int=0, hours:int=0, minutes:int=0, seconds:int=0, frames:int=0, dropFrame:Boolean = false):String
		{
			var h:String = TimeCode.twoDigits(hours),
				m:String = TimeCode.twoDigits(minutes),
				s:String = TimeCode.twoDigits(seconds),
				f:String = TimeCode.twoDigits(frames),
				framesSeparator:String = (dropFrame) ? ";" : ":";
			
			if (days > 0)
			{
				return StringUtils.formatString("{0}:{1}:{2}:{3}{5}{4}", days, h, m, s, f, framesSeparator);
			}
			
			return StringUtils.formatString("{0}:{1}:{2}{4}{3}", h, m, s, f, framesSeparator);
		}
		
		/**
		 * Converts to Absolute time from SMPTE 12M 23.98.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_23_98_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 24)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 23.98 IVTC.");
			}
			
			var framesHertz:Number = Math.ceil(1001 * (15 / 4) * frames);
			var secondsHertz:int = 90090 * seconds;
			var minutesHertz:int = 5405400 * minutes;
			var hoursHertz:Number = 324324000 * hours;
			var daysHertz:Number = 7783776000 * days;
			
			var pcrTb:Number = framesHertz + secondsHertz + minutesHertz + hoursHertz + daysHertz;
			
			var ticks27Mhz:Number = pcrTb * 300;
			
			return new AbsoluteTimeHelper(ticks27Mhz,NumberType.ULONG);
		}
		
		/**
		 * Converts to Absolute time from SMPTE 12M 24.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_24_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 24)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 24fps Film Sync.");
			}
			;
			var ticks27Mhz:Number = ((3750 * frames) + (90000 * seconds) + (5400000 * minutes) + (324000000 * hours) + (7776000000 * days)) * 300;
			
			var ath:AbsoluteTimeHelper = new AbsoluteTimeHelper(ticks27Mhz,NumberType.ULONG);
			
			return ath;
		}
		
		/**
		 * Converts to Absolute time from SMPTE 12M 25.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_25_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 25)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 25fps PAL.");
			}
			
			var ticks27Mhz:Number = ((3600 * frames) + (90000 * seconds) + (5400000 * minutes) + (324000000 * hours) + (7776000000 * days)) * 300;
			return new AbsoluteTimeHelper(ticks27Mhz,NumberType.ULONG);
		}
		
		/**
		 * Converts to Absolute time from SMPTE 12M 29.97 Drop frame.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_29_97_Drop_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 30)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 29.97 DropFrame.");
			}
			
			var time:Number = (1001 / 30000) * (frames + (30 * seconds) + (1798 * minutes) + ((2 * (minutes / 10)) + (107892 * hours) + (2589408 * days)));
			return new AbsoluteTimeHelper(time,NumberType.DOUBLE);
		}
		
		/**
		 * Converts to Absolute time from SMPTE 12M 29.97 Non Drop.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_29_97_NonDrop_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 30)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 29.97 NonDrop.");
			}
			
			var ticks27Mhz:Number = ((3003 * frames) + (90090 * seconds) + (5405400 * minutes) + (324324000 * hours) + (7783776000 * days)) * 300;
			return new AbsoluteTimeHelper(ticks27Mhz,NumberType.ULONG);			
		}
		
		
		/**
		 * Converts to Absolute time from SMPTE 12M 30.
		 * 
		 * @param timeCode The timecode to parse.
		 * @returns An AbsoluteTimeHelper that contains the absolute duration.
		 */
		private static function smpte12M_30_ToAbsoluteTime(timeCode:String):AbsoluteTimeHelper
		{
			var obj:TimeCodeComponents = TimeCode.parseTimecodeString(timeCode);
			var days:int = obj.days, 
				hours:int = obj.hours, 
				minutes:int = obj.minutes, 
				seconds:int = obj.seconds, 
				frames:int = obj.frames;
			
			if (frames >= 30)
			{
				throw new Error("Timecode frame value is not in the expected range for SMPTE 30fps.");
			}
			
			var ticks27Mhz:Number = ((3000 * frames) + (90000 * seconds) + (5400000 * minutes) + (324000000 * hours) + (7776000000 * days)) * 300;
			return new AbsoluteTimeHelper(ticks27Mhz,NumberType.ULONG);			
		}
		
		/**
		 * Converts from 27Mhz ticks to PCRTb.
		 * 
		 * @param ticks27Mhz >The number of 27Mhz ticks to convert from.
		 * @returns A Number with the PCRTb.
		 */
		internal static function ticks27MhzToPcrTb(ticks27Mhz:Number):Number
		{
			return ticks27Mhz / 300;
		}
		
		/**
		 * Converts the provided absolute time to PCRTb.
		 * 
		 * @param time Absolute time to be converted.
		 * @returns The number of PCRTb ticks.
		 */
		internal static function absoluteTimeToTicksPcrTb(time:AbsoluteTimeHelper):Number
		{
			return Math.round(time.timeAsDouble * 90000);
		}
		
		/**
		 * Converts the specified absolute time to 27 mhz ticks.
		 * 
		 * @param time Absolute time to be converted.
		 * @returns The number of 27Mhz ticks.
		 */
		internal static function absoluteTimeToTicks27Mhz(time:AbsoluteTimeHelper):Number
		{
			return  TimeCode.absoluteTimeToTicksPcrTb(time) * 300;
		}
		
		/**
		 * Converts the specified absolute time to absolute time.
		 * 
		 * @param ticksPcrTb Ticks PCRTb to be converted.
		 * @returns The absolute time.
		 */
		internal static function ticksPcrTbToAbsoluteTime(ticksPcrTb:Number):Number
		{
			return ticksPcrTb / 90000;
		}
		
		/**
		 * Converts the specified absolute time to absolute time.
		 * 
		 * @param ticks27Mhz Ticks 27Mhz to be converted.
		 * @returns The absolute time.
		 */
		internal static function ticks27MhzToAbsoluteTime(ticks27Mhz:Number):Number
		{
			var ticksPcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			return  TimeCode.ticksPcrTbToAbsoluteTime(ticksPcrTb);
		}
		
		/**
		 * Converts to SMPTE 12M.
		 *
		 * @param time The absolute time to convert from.
		 * @param rate The SMPTE frame rate.
		 * @returns A string in SMPTE 12M format.
		 */
		private static function absoluteTimeToSmpte12M(time:AbsoluteTimeHelper, rate:SmpteFrameRate):String
		{
			var timeCode:String = "";
			
			if (rate == SmpteFrameRate.SMPTE_2398)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_23_98fps(time);
			}
			else if (rate == SmpteFrameRate.SMPTE_24)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_24fps(time);
			}
			else if (rate == SmpteFrameRate.SMPTE_25)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_25fps(time);
			}
			else if (rate == SmpteFrameRate.SMPTE_2997_DROP)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_29_97_Drop(time);
			}
			else if (rate == SmpteFrameRate.SMPTE_2997_NONDROP)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_29_97_NonDrop(time);
			}
			else if (rate == SmpteFrameRate.SMPTE_30)
			{
				timeCode = TimeCode.absoluteTimeToSmpte12M_30fps(time);
			}
			
			return timeCode;
		}
		
		/**
		 * Returns the absolute time.
		 * 
		 * @param frames  The number of frames.
		 * @param rate The SMPTE frame rate to use for the conversion.
		 * @returns The absolute time.
		 */
		private static function framesToAbsoluteTime(frames:Number, rate:SmpteFrameRate):Number
		{
			var absoluteTimeInDecimal:Number;
			
			if (rate == SmpteFrameRate.SMPTE_2398)
			{
				absoluteTimeInDecimal = frames / 24 / (1000 / 1001);
			}
			else if (rate == SmpteFrameRate.SMPTE_24)
			{
				absoluteTimeInDecimal = frames / 24;
			}
			else if (rate == SmpteFrameRate.SMPTE_25)
			{
				absoluteTimeInDecimal = frames / 25;
			}
			else if (rate == SmpteFrameRate.SMPTE_2997_DROP || rate == SmpteFrameRate.SMPTE_2997_NONDROP)
			{
				absoluteTimeInDecimal = frames / 30 / (1000 / 1001);
			}
			else if (rate == SmpteFrameRate.SMPTE_30)
			{
				absoluteTimeInDecimal = frames / 30;
			}
			else
			{
				absoluteTimeInDecimal = frames / 30;
			}
			
			return absoluteTimeInDecimal;
		}
		
		/**
		 * Returns the absolute time.
		 * 
		 * @param frames  The number of frames.
		 * @param rate The SMPTE frame rate to use for the conversion.
		 * @returns The absolute time.
		 */
		private static function framesToTicks27Mhz(frames:Number, rate:SmpteFrameRate):Number
		{
			var ticks27Mhz:Number;
			
			if (rate == SmpteFrameRate.SMPTE_2398)
			{
				ticks27Mhz = Math.ceil(1001 * (15 / 4) * frames) * 300;
			}
			else if (rate == SmpteFrameRate.SMPTE_24)
			{
				ticks27Mhz = (3750 * frames) * 300;
			}
			else if (rate == SmpteFrameRate.SMPTE_25)
			{
				ticks27Mhz = (3600 * frames) * 300;
			}
			else if (rate == SmpteFrameRate.SMPTE_2997_DROP || rate == SmpteFrameRate.SMPTE_2997_NONDROP)
			{
				ticks27Mhz = (3003 * frames) * 300;
			}
			else if (rate == SmpteFrameRate.SMPTE_30)
			{
				ticks27Mhz = (3000 * frames) * 300;
			}
			else
			{
				ticks27Mhz = (3000 * frames) * 300;
			}
			
			return ticks27Mhz;
		}
		
		/**
		 * Returns the absolute time.
		 * 
		 * @param absoluteTime The number of frames.
		 * @param rate The SMPTE frame rate to use for the conversion.
		 * @returns The absolute time.
		 */
		private static function absoluteTimeToFrames(absoluteTime:AbsoluteTimeHelper, rate:SmpteFrameRate):Number
		{
			var frames:Number;
			
			if (rate == SmpteFrameRate.SMPTE_2398)
			{
				frames = ((4 / 15) * (absoluteTime.pcrTime / 1001));
				return frames;
			}
			
			if (rate == SmpteFrameRate.SMPTE_24)
			{
				frames = (absoluteTime.pcrTime / 3750);
				return frames;
			}
			
			if (rate == SmpteFrameRate.SMPTE_25)
			{
				frames = (absoluteTime.pcrTime / 3600);
				return frames;
			}
			
			if (rate == SmpteFrameRate.SMPTE_2997_DROP || rate == SmpteFrameRate.SMPTE_2997_NONDROP)
			{
				frames = (absoluteTime.pcrTime / 3003);
				return frames;
			}
			
			if (rate == SmpteFrameRate.SMPTE_30)
			{
				frames = (absoluteTime.pcrTime / 3000);
				return frames;
			}
			
			return (absoluteTime.pcrTime / 3003);
		}
		
		/**
		 *  Returns the SMPTE 12M 23.98 timecode.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_23_98fps(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_23_98fps(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to SMPTE 12M 24fps.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_24fps(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_24fps(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to SMPTE 12M 25fps.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_25fps(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_25fps(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to SMPTE 12M 29.97fps Drop.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_29_97_Drop(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_29_27_Drop(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to SMPTE 12M 29.97fps Non Drop.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_29_97_NonDrop(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_29_27_NonDrop(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to SMPTE 12M 30fps.
		 *  
		 *  @param absoluteTime The absolute time to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function absoluteTimeToSmpte12M_30fps(absoluteTime:AbsoluteTimeHelper):String
		{
			return TimeCode.ticks27MhzToSmpte12M_30fps(absoluteTime.time27Mhz);
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_30fpsToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_30);
			var ticksPcrTb:Number = Math.ceil((t.framesSegment * 3000) + (90000 * t.secondsSegment) + (5400000 * t.minutesSegment) + (324000000 * t.hoursSegment));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_23_98fpsToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_2398);
			var ticksPcrTb:Number = Math.ceil((Math.ceil(1001 * (15 / 4) * t.framesSegment) + (90090 * t.secondsSegment) + (5405400 * t.minutesSegment) + (324324000 * t.hoursSegment)));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_24fpsToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_24);
			var ticksPcrTb:Number = Math.ceil((t.framesSegment * 3750) + (90000 * t.secondsSegment) + (5400000 * t.minutesSegment) + (324000000 * t.hoursSegment));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_25fpsToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_25);
			var ticksPcrTb:Number = Math.ceil((t.framesSegment * 3600) + (90000 * t.secondsSegment) + (5400000 * t.minutesSegment) + (324000000 * t.hoursSegment));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_29_27_NonDropToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_2997_DROP);
			var ticksPcrTb:Number = Math.ceil((t.framesSegment * 3003) + (90090 * t.secondsSegment) + (5405400 * t.minutesSegment) + (324324000 * t.hoursSegment));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to Ticks 27Mhz.
		 * 
		 *  @param timeCode The timecode to convert from.
		 *  @returns The number of 27Mhz ticks.
		 */
		private static function smpte12M_29_27_DropToTicks27Mhz(timeCode:String):Number
		{
			var t:TimeCode = new TimeCode(timeCode, SmpteFrameRate.SMPTE_2997_NONDROP);
			var ticksPcrTb:Number = Math.ceil((3003 * t.framesSegment) + (90090 * t.secondsSegment) + (5399394 * t.minutesSegment) + (6006 * int(t.minutesSegment / 10)) + (323999676 * t.hoursSegment));
			return ticksPcrTb * 300;
		}
		
		/**
		 *  Converts to SMPTE 12M 29.27fps Non Drop.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_29_27_NonDrop(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int = int(pcrTb / 3003);
			var hours:int = int(framecount / 108000);
			var minutes:int = int((framecount - (108000 * hours)) / 1800);
			var seconds:int = int((framecount - (1800 * minutes) - (108000 * hours)) / 30);
			var frames:int = framecount - (30 * seconds) - (1800 * minutes) - (108000 * hours);
			
			var days:int = hours / 24;
			hours = hours % 24;
			
			return TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, false);
		}
		
		/**
		 *  Converts to SMPTE 12M 29.27fps Non Drop.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_29_27_Drop(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int = int(pcrTb / 3003);
			var hours:int = int(framecount / 107892);
			var minutes:int = int((framecount + (2 * int((framecount - (107892 * hours)) / 1800)) - (2 * int((framecount - (107892 * hours)) / 18000)) - (107892 * hours)) / 1800);
			var seconds:int = int((framecount - (1798 * minutes) - (2 * int(minutes / 10)) - (107892 * hours)) / 30);
			var frames:int = framecount - (30 * seconds) - (1798 * minutes) - (2 * int(minutes / 10)) - (107892 * hours);
			
			var days:int = hours / 24;
			hours = hours % 24;
			
			return TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, true);
		}
		
		/**
		 *  Converts to SMPTE 12M 23.98fps.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_23_98fps(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int =int((4 / 15) * (pcrTb / 1001));
			var days:int = int((framecount / 86400) / 24);
			var hours:int = int((framecount / 86400) % 24);
			var minutes:int = int((framecount - (86400 * hours)) / 1440) % 60;
			var seconds:int = int((framecount - (1440 * minutes) - (86400 * hours)) / 24) % 60;
			var frames:int = (framecount - (24 * seconds) - (1440 * minutes) - (86400 * hours)) % 24;
			
			return TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, false);
		}
		
		/**
		 *  Converts to SMPTE 12M 24fps.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_24fps(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int =int(pcrTb / 3750);
			var days:int = int((framecount / 86400) / 24);
			var hours:int = int((framecount / 86400) % 24);
			var minutes:int = int((framecount - (86400 * hours)) / 1440) % 60;
			var seconds:int = int((framecount - (1440 * minutes) - (86400 * hours)) / 24) % 60;
			var frames:int = (framecount - (24 * seconds) - (1440 * minutes) - (86400 * hours)) % 24;
			
			return TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, false);
		}
		
		/**
		 *  Converts to SMPTE 12M 25fps.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_25fps(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int =int(pcrTb / 3600);
			var days:int = int((framecount / 90000) / 24);
			var hours:int = int((framecount / 90000) % 24);
			var minutes:int = int((framecount - (90000 * hours)) / 1500) % 60;
			var seconds:int = int((framecount - (1500 * minutes) - (90000 * hours)) / 25) % 60;
			var frames:int = (framecount - (25 * seconds) - (1500 * minutes) - (90000 * hours)) % 25;
			
			return TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, false);
		}
		
		/**
		 *  Converts to SMPTE 12M 30fps.
		 * 
		 *  @param ticks27Mhz The number of 27Mhz ticks to convert from.
		 *  @returns A string that contains the correct format.
		 */
		private static function ticks27MhzToSmpte12M_30fps(ticks27Mhz:Number):String
		{
			var pcrTb:Number = TimeCode.ticks27MhzToPcrTb(ticks27Mhz);
			var framecount:int =int(pcrTb / 3000);
			var days:int = int((framecount / 108000) / 24);
			var hours:int = int((framecount / 108000) % 24);
			var minutes:int = int((framecount - (108000 * hours)) / 1800) % 60;
			var seconds:int = int((framecount - (1800 * minutes) - (108000 * hours)) / 30) % 60;
			var frames:int = (framecount - (30 * seconds) - (1800 * minutes) - (108000 * hours)) % 30;
			
			return  TimeCode.formatTimeCodeString(days, hours, minutes, seconds, frames, false);
		}
	}
}
