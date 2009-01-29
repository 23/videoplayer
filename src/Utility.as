// Random utility functions and methods
import flash.system.Capabilities;

public function displayError(text:String):void {logo.visible=false; video.visible=false; image.visible=false; tray.visible=false; errorContainer.visible=true; errorContainer.text=text;}
public function formatTime(time:int):String {return(Math.floor(time/60).toString() +':'+ (time%60<10?'0':'') + Math.round(time%60).toString());}
public function recalcBindPositions():void {Application.application.updateDisplayList(0,0);}
public function referer():String {return(Application.application.url);}

public function h264():Boolean {
	var re:RegExp = new RegExp('([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)', 'img');
	var v:Array = re.exec(Capabilities.version);
	if (v[1]>9) {return(true);}
	if (v[1]==9 && (v[2]>0 || v[3]>=115)) {return(true);}
	return(false);
}
