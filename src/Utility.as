// Random utility functions and methods
import flash.system.Capabilities;

import mx.utils.UIDUtil;

public var uuid:String = UIDUtil.createUID();

public function displayError(text:String):void {
	logo.visible=false; 
	video.visible=false; 
	image.visible=false; 
	tray.visible=false; 
	errorContainer.visible=true; 
	errorText.text=text;
}


public function h264():Boolean {
	var re:RegExp = new RegExp('([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)', 'img');
	var v:Array = re.exec(Capabilities.version);
	if (v[1]>9) {return(true);}
	if (v[1]==9 && (v[2]>0 || v[3]>=115)) {return(true);}
	return(false);
}

public function expandReportObject(o:Object):Object {
	o['source'] = props.getString('source');
	o['referer'] = props.getString('referer');
	o['user_player_type'] = 'flash';
	o['user_player_resolution'] = Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
	o['user_player_version'] = Capabilities.version;
	return(o);
}

private var lastPlayTimeStart:String = '0';
public function reportPlay(event:String, time:Number):void {
	try {
		if(event=='start' || time<=0) {
			var time_start:String = new String(time+activeElement.getNumber('start'));
			lastPlayTimeStart = time_start;
			var time_end:String = ''; 
		} else if(event=='continue') {
			var time_start:String = lastPlayTimeStart;
			var time_end:String =  new String((playbackReportInterval/2)+time+activeElement.getNumber('start'));
		} else {
			var time_start:String = lastPlayTimeStart;
			var time_end:String =  new String(time+activeElement.getNumber('start'));
		}
		var time_total:String = (video.totalTime>0 ? new String(video.totalTime + activeElement.getNumber('start')) : '');
		var photo_id:int = context.photos[currentElementIndex].photo_id;
		doAPI('/api/analytics/report/play', expandReportObject({photo_id:photo_id, timeStart:time_start, timeEnd:time_end, timeTotal:time_total, uuid:uuid}), function():void{});
	} catch(e:Error) {}
}
public function reportEvent(event:String):void {
	try {
		var photo_id:int = context.photos[currentElementIndex].photo_id;
		doAPI('/api/analytics/report/event', expandReportObject({photo_id:photo_id, event:event, uuid:uuid}), function():void{});
	} catch(e:Error) {}
}

public function goToUrl(url:String, target:String = '_top'):void {
	if(!new RegExp('\:\/\/').test(url)) url = props.get('site_url') + url;
    navigateToURL(new URLRequest(url), target);
}
public function updateBackground():void {
	try {
		if(ExternalInterface.available) {
			ExternalInterface.call('setBackground', props.getString('backgroundColor'), activeElement.get('photoSource'), props.getNumber('verticalPadding'), props.getNumber('horizontalPadding'));
		}
	} catch(e:Error) {}
}