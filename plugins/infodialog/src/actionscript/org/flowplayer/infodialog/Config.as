
package org.flowplayer.infodialog {

    import org.flowplayer.ui.buttons.ToggleButtonConfig;
    import org.flowplayer.ui.buttons.TooltipButtonConfig;
    import org.flowplayer.ui.controllers.*;
	
	public class Config {
       // private var _visible:WidgetsVisibility = null;
        private var _style:Object =   {
			buttonColor: "#c1c1c1",
			disabledWidgetColor: "#4e4e4e", 
			buttonOverColor: "#00b4e6",
			buttonOffColor: "rgba(0,0,0,1)"
		};

        public function set availableWidgets(widgetControllers:Array):void {

           // _visible  = new WidgetsVisibility(_style, widgetControllers);
        }


        public function get buttonConfig():TooltipButtonConfig {
            var config:TooltipButtonConfig = new TooltipButtonConfig();
            config.setColor(_style['buttonColor']);
            config.setDisabledColor(_style['disabledWidgetColor']);
            config.setOverColor(_style['buttonOverColor']);

            config.setOffColor(_style['buttonOffColor']);
            config.setOnColor(_style['buttonColor']);

            config.setTooltipColor(_style['tooltipColor']);
            config.setTooltipTextColor(_style['tooltipTextColor']);
            
            return config;
        }
    
        public function getButtonConfig(name:String = null):TooltipButtonConfig {
            var config:TooltipButtonConfig = buttonConfig;
            return config;
        }
    
        public function getWidgetConfiguration(controller:Object):Object {
            return new ToggleButtonConfig(
                            getButtonConfig(controller.name), 
                            getButtonConfig((controller as AbstractToggleButtonController).downName));
 
        }

        public function get canvas():Object {

            return {
                border: 'none',
                backgroundColor: 'rgba(0, 0, 0, 255)',
            
                '.label': {
                    fontSize: 16,
                    fontFamily: "黑体",
                    textAlign: 'center',
                    color: '#ffffff'
                }
            }
        }

    }
}
