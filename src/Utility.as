// Random utility functions and methods
import flash.system.Capabilities;

import mx.utils.UIDUtil;

import preload.CustomPreloader;
public var uuid:String = UIDUtil.createUID();

public function displayError(text:String):void {
	logo.visible=false; 
	video.visible=false; 
	image.visible=false; 
	tray.visible=false; 
	errorContainer.visible=true; 
	errorContainer.text=text;
}

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

public function expandReportObject(o:Object):Object {
	o['user_player_type'] = 'flash';
	o['user_player_resolution'] = Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
	o['user_player_version'] = Capabilities.version;
	return(o);
}

private var lastPlayTimeStart:String = '0';
public function reportPlay(event:String, time:Number):void {
	if(event=='start' || time<=0) {
		var time_start:String = new String(time+activeElement.getNumber('start'));
		lastPlayTimeStart = time_start;
		var time_end:String = ''; 
	} else {
		var time_start:String = lastPlayTimeStart;
		var time_end:String =  new String(time+activeElement.getNumber('start'));
	}
	var time_total:String = (video.totalTime>0 ? new String(video.totalTime + activeElement.getNumber('start')) : '');
	var photo_id:int = context.photos[currentElementIndex].photo_id;

	try {
		ExternalInterface.call('callbackEvent', 'play', expandReportObject({photo_id:photo_id, time_start:time_start, time_end:time_end, time_total:time_total, uuid:uuid}));
	}catch(e:Error){}

	try {
		doAPI('/api/analytics/report/play', expandReportObject({photo_id:photo_id, time_start:time_start, time_end:time_end, time_total:time_total, uuid:uuid}), function():void{});
	} catch(e:Error) {subtitles.suppportedLocales = {}; subtitlesMenu.options = [];}
}
public function reportEvent(event:String):void {
	var photo_id:int = context.photos[currentElementIndex].photo_id;
	try {
		ExternalInterface.call('callbackEvent', event, expandReportObject({photo_id:photo_id, event:event, uuid:uuid}));
	}catch(e:Error){}
	try {
		doAPI('/api/analytics/report/event', expandReportObject({photo_id:photo_id, event:event, uuid:uuid}), function():void{});
	} catch(e:Error) {subtitles.suppportedLocales = {}; subtitlesMenu.options = [];}
}

public function goToUrl(url:String):void {
	if(!new RegExp('\:\/\/').test(url)) url = props.get('site_url') + url;
    navigateToURL(new URLRequest(url), "_top");
}

