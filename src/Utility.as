// Random utility functions and methods
import flash.system.Capabilities;

import mx.utils.UIDUtil;

import preload.CustomPreloader;
public var uuid:String = UIDUtil.createUID();

public function displayError(text:String):void {logo.visible=false; video.visible=false; image.visible=false; tray.visible=false; errorContainer.visible=true; errorContainer.text=text;}

public function lowBandwidth():Boolean {
	return(preload.CustomPreloader.kbps < props.get('lowBandwidthThresholdKbps'));
}

public function h264():Boolean {
	if(lowBandwidth()) return(false);
	var re:RegExp = new RegExp('([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)', 'img');
	var v:Array = re.exec(Capabilities.version);
	if (v[1]>9) {return(true);}
	if (v[1]==9 && (v[2]>0 || v[3]>=115)) {return(true);}
	return(false);
}

public function reportPlayTime(time:Number):void {
	var id:int = context.photos[currentElementIndex].photo_id;
	var url:String = 'http://' + props.get('domain') + '/actions?action=report-play-time&uuid=' + encodeURIComponent(uuid) + '&id=' + encodeURIComponent(new String(id)) + '&time=' + encodeURIComponent(new String(time));
	var reportRequest:URLRequest = new URLRequest(url);
	var reportLoader:URLLoader = new URLLoader();
	reportLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {});
	reportLoader.addEventListener(IOErrorEvent.IO_ERROR, function httpStatusHandler(e:Event):void {});
	reportLoader.load(reportRequest);	
}

public function goToUrl(url:String):void {
	if(!new RegExp('\:\/\/').test(url)) url = 'http://' + props.get('domain') + url;
    navigateToURL(new URLRequest(url),"_blank");
}
