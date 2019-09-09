package  {

import org.flowplayer.controls.Controls;
import org.flowplayer.quickmenu.QuickMenu;
import org.flowplayer.pseudostreaming.PseudoStreaming;
import org.flowplayer.optionsdialog.OptionsDialog;
import org.flowplayer.infodialog.InfoDialog;
import org.flowplayer.rtmp.RTMPStreaming;

public class BuiltInConfig {

    private var controls:org.flowplayer.controls.Controls;
      private var pseudo:org.flowplayer.pseudostreaming.PseudoStreamProvider;
      private var quickmenu:org.flowplayer.quickmenu.QuickMenu;
      private var optionsdialog:org.flowplayer.optionsdialog.OptionsDialog;
      private var infodialog:org.flowplayer.infodialog.InfoDialog;
	  private var rtmp:org.flowplayer.rtmp.RTMPStreamProvider;

    public static const config:Object = { 
       "plugins": {
          "pseudo": {
              "url": 'org.flowplayer.pseudostreaming.PseudoStreamProvider'
          },

          "controls": {
              "url": 'org.flowplayer.controls.Controls'
  		  },
          "quickmenu": {
              "url": 'org.flowplayer.quickmenu.QuickMenu'
          },
          "optionsdialog": {
              "url": 'org.flowplayer.optionsdialog.OptionsDialog'
          },
          "info": {
              "url": 'org.flowplayer.infodialog.InfoDialog'
          },
		  "rtmp": {
			  "url": 'org.flowplayer.rtmp.RTMPStreamProvider'
		  }
        }
      }
    }; 
}