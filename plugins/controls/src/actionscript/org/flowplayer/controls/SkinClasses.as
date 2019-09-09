package org.flowplayer.controls {
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.system.ApplicationDomain;
    import flash.utils.getDefinitionByName;
    import org.flowplayer.util.Log;

	import fp.*;

    /**
     * Holds references to classes contained in the buttons.swc lib.
     * These are needed here because the classes are instantiated dynamically and without these
     * the compiler will not include thse classes into the controls.swf
     */
    public class SkinClasses {
        private static var log:Log = new Log("org.flowplayer.controls.buttons::SkinClasses");
        private static var _skinClasses:ApplicationDomain;

		// imports all assets of default buttons to controls.swf
		CONFIG::skin {
            private var foo:fp.FullScreenOnButton;
            private var bar:fp.FullScreenOffButton;
            private var screenCaptureOff:fp.ScreenCaptureOffButton;
            private var screenCaptureOn:fp.ScreenCaptureOnButton;
            private var next:fp.NextButton;
            private var prev:fp.PrevButton;
            private var dr:fp.Dragger;
            private var pause:fp.PauseButton;
            private var play:fp.PlayButton;
            private var stop:fp.StopButton;
            private var vol:fp.MuteButton;
            private var volOff:fp.UnMuteButton;
            private var scrubberLeft:fp.ScrubberLeftEdge;
            private var scrubberRight:fp.ScrubberRightEdge;
            private var scrubberTop:fp.ScrubberTopEdge;
            private var scrubberBottom:fp.ScrubberBottomEdge;
            private var buttonLeft:fp.ButtonLeftEdge;
            private var buttomRight:fp.ButtonRightEdge;
            private var buttomTop:fp.ButtonTopEdge;
            private var buttonBottom:fp.ButtonBottomEdge;
            private var timeLeft:fp.TimeLeftEdge;
            private var timeRight:fp.TimeRightEdge;
            private var timeTop:fp.TimeTopEdge;
            private var timeBottom:fp.TimeBottomEdge;
            private var volumeLeft:fp.VolumeLeftEdge;
            private var volumeRight:fp.VolumeRightEdge;
            private var volumeTop:fp.VolumeTopEdge;
            private var volumeBottom:fp.VolumeBottomEdge;
        }
        

        public static function getDisplayObject(name:String):DisplayObjectContainer {
            var clazz:Class = getClass(name);
            return new clazz() as DisplayObjectContainer;
        }

        public static function getClass(name:String):Class {
            log.debug("creating skin class " + name + (_skinClasses ? "from skin swf" : ""));
            if (_skinClasses) {
                return _skinClasses.getDefinition(name) as Class;
            }
            return getDefinitionByName(name) as Class;
        }

        public static function get defaults():Object {
            return {
                bottom: 0, 
                left: '50%', 
                height: "50", 
                width: "100%", 
                zIndex: 2,
                backgroundColor: "rgba(39, 39, 39, 0.7)",
                //backgroundGradient: [.5, 0, 0.3],
                border: "0px",
                borderRadius: "0px",
                timeColor: "#ffffff",
                durationColor: "#a3a3a3",
                
                sliderColor: "#000000",
                sliderGradient: "none",
                volumeColor: '#00b4e6',
                volumeSliderColor: "#000000",
                volumeSliderGradient: "none",
                buttonColor: "#c1c1c1",
                disabledWidgetColor: "#4e4e4e",   // used for all buttons and widgets
                buttonOverColor: "#00b4e6",
                buttonOffColor: "rgba(0,0,0,1)",
                progressColor: "#00b4e6",
                progressGradient: "none",
                bufferColor: "#a3a3a3",
                bufferGradient: "none",
                tooltipColor: "#000000",
                tooltipTextColor: "#ffffff",
                timeBgColor: 'rgb(0, 0, 0, 0)',
                timeBorder: '0px solid rgba(0, 0, 0, 0.3)',
                timeBorderRadius: 20,
                // what percentage the scrubber handle should take of the controlbar total height
                scrubberHeightRatio: 0.8,
                // what percentage the scrubber horizontal bar should take of the controlbar total height
                scrubberBarHeightRatio: 0.4,
                
                // what percentage the volume slider handle should take of the controlbar total height
                volumeSliderHeightRatio: 0.4,
                // what percentage the horizontal volume bar should take of the controlbar total height
                volumeBarHeightRatio: 0.4,
                
                // how much the time view colored box is of the total controlbar height
                timeBgHeightRatio:  0.8,
                
                timeSeparator: " ",
                timeFontSize: 12,
                
                volumeBorder: '1px solid rgba(128, 128, 128, 0.7)',
                sliderBorder: '1px solid rgba(128, 128, 128, 0.7)',
                
                margins: [2, 12, 2, 12],
                
                autoHide: { 
                    enabled: true,
                    fullscreenOnly: false, 
                    delay: 2000, 
                    duration: 1000, 
                    style: 'fade' 
                },
                spacing: { all: 2, volume: 8, time: 6 }
            }
        }

        public static function getScrubberRightEdgeWidth(nextWidgetToRight:DisplayObjectContainer):Number {
            try {
                var clazz:Class = getClass("SkinDefaults");
                return clazz["getScrubberRightEdgeWidth"](nextWidgetToRight);
            } catch (e:Error) {
            }
            return 0;
        }

		public static function getVolumeSliderWidth():Number {
            return 100;
        }

        public static function set skinClasses(val:ApplicationDomain):void {
            log.debug("received skin classes " + val);
            _skinClasses = val;
        }


    }
}