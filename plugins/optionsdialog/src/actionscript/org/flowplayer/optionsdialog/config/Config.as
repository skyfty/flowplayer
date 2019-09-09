
package org.flowplayer.optionsdialog.config
{
    import org.flowplayer.ui.buttons.ButtonConfig;
    import org.flowplayer.util.PropertyBinder;

    public class Config {
        private var _canvas:Object;
        private var _buttonConfig:ButtonConfig;
        private var _closeButton:ButtonConfig;
        private var _pauseVideo:Boolean = true;

        public function get canvas():Object {
            if (! _canvas) {
                _canvas = {
                    border: '1px',
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    
                    '.title': {
                        fontSize: 13,
                        color: '#ffffff'
                    },
                    '.label': {
                        fontSize: 12
                    },
                    '.input': {
                        fontSize: 12,
                        color: '#000000',
                        backgroundColor: '#ffffff'
                    }
                };
            }
            return _canvas;
        }

        public function set canvas(value:Object):void {
            var canvasConfig:Object = canvas;
            for (var prop:String in value) {
                canvasConfig[prop] = value[prop];
            }
        }

        static public function defaultButtonConfig() : ButtonConfig {
            var btnConfig:ButtonConfig = new ButtonConfig();
            //btnConfig.setColor("rgba(180,180,180,0.6)");
            //btnConfig.setOverColor("rgba(140,142,140,1)");
            btnConfig.setFontColor("rgb(255,255,0)");
            btnConfig.setDisabledColor("rgba(100, 100, 100, 0.7)");
            btnConfig.setDisableFontColor("rgba(140,142,140,1)");
            return btnConfig;            
        }

        public function get buttons():ButtonConfig {
            if (! _buttonConfig) {
                _buttonConfig = defaultButtonConfig();          
            }
            return _buttonConfig;
        }

        public function get closeButton():ButtonConfig {
            if (! _closeButton) {
                _closeButton = new ButtonConfig();
                _closeButton.setColor("rgba(80,80,80,0.8)");
                _closeButton.setOverColor("rgba(120,120,120,1)");
            }
            return _closeButton;
        }

        public function setButtons(config:Object):void {
            new PropertyBinder(buttons).copyProperties(config);
        }

        public function setCloseButton(config:Object):void {
            new PropertyBinder(closeButton).copyProperties(config);
        }


        public function set pauseVideo(pause:Boolean):void {
            _pauseVideo = pause;
        }

        public function get pauseVideo():Boolean {
            return _pauseVideo;
        }
    }
}



