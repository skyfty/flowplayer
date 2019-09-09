package org.flowplayer.quickmenu {
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
        private static var log:Log = new Log("org.flowplayer.quickmenu.buttons::SkinClasses");
        private static var _skinClasses:ApplicationDomain;

		// imports all assets of default buttons to controls.swf
		CONFIG::skin {
            private var foo:fp.FullScreenOnButton;
            private var bar:fp.FullScreenOffButton;

            private var screenCaptureOff:fp.ScreenCaptureOffButton;
            private var screenCaptureOn:fp.ScreenCaptureOnButton;

            private var optionDialogOn:fp.OptionDialogOnButton;
            //private var optionDialogOff:fp.OptionDialogOffButton;

            private var buttonLeft:fp.ButtonLeftEdge;
            private var buttomRight:fp.ButtonRightEdge;
            private var buttomTop:fp.ButtonTopEdge;
            private var buttonBottom:fp.ButtonBottomEdge;
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
                top: 0, 
                left: '50%', 
                height: 23, 
                width: "100%", 
                zIndex: 3,
                backgroundColor: "rgba(39, 39, 39, 0.5)",
                //backgroundGradient: [.5, 0, 0.3],
                border: "0px",
                borderRadius: "0px",
                
                buttonColor: "#c1c1c1",
                disabledWidgetColor: "#4e4e4e",   // used for all buttons and widgets
                buttonOverColor: "#00b4e6",
                buttonOffColor: "rgba(0,0,0,1)",
                
                tooltipColor: "#000000",
                tooltipTextColor: "#ffffff",
                
                margins: [2, 12, 2, 12],
                
                autoHide: { 
                    enabled: true,
                    fullscreenOnly: false, 
                    delay: 2000, 
                    duration: 1000, 
                    style: 'fade' 
                }
            }
        }

        public static function set skinClasses(val:ApplicationDomain):void {
            log.debug("received skin classes " + val);
            _skinClasses = val;
        }
    }
}