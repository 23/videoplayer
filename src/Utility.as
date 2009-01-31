// Random utility functions and methods
import flash.system.Capabilities;

import mx.utils.UIDUtil;
public var uuid:String = UIDUtil.createUID();

public function displayError(text:String):void {logo.visible=false; video.visible=false; image.visible=false; tray.visible=false; errorContainer.visible=true; errorContainer.text=text;}
public function formatTime(time:int):String {return(Math.floor(time/60).toString() +':'+ (time%60<10?'0':'') + Math.round(time%60).toString());}
public function recalcBindPositions():void {Application.application.updateDisplayList(0,0);}

public function h264():Boolean {
	var re:RegExp = new RegExp('([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)', 'img');
	var v:Array = re.exec(Capabilities.version);
	if (v[1]>9) {return(true);}
	if (v[1]==9 && (v[2]>0 || v[3]>=115)) {return(true);}
	return(false);
}

public function reportPlayTime(time:Number):void {
	var id:int = context.photos[currentElementIndex].photo_id;
	var url:String = 'http://' + props.get('domain') + '/actions?method=report_play_time&uuid=' + encodeURIComponent(uuid) + '&id=' + encodeURIComponent(new String(id)) + '&time=' + encodeURIComponent(new String(time));
	var reportRequest:URLRequest = new URLRequest(url);
	var reportLoader:URLLoader = new URLLoader();
	reportLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {});
	reportLoader.addEventListener(IOErrorEvent.IO_ERROR, function httpStatusHandler(e:Event):void {});
	reportLoader.load(reportRequest);	
}
