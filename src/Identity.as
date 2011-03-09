import flash.events.MouseEvent;
import flash.utils.Timer;

import mx.events.VideoEvent;

public var currentIdentityEvent = '';
public function showIdentityVideo(event:String, url:String, link:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	identityVideo.visible = true;
	identityVideo.source = url;
	identityVideo.play();
	identityVideo.addEventListener(MouseEvent.CLICK, function():void{
			reportEvent(event=='before' ? 'preRollClick' : 'postRollClick');
			goToUrl(link);
		});
	var onComplete:Function = function():void {
			if(!identityVideo.visible) return;
			identityVideo.visible = false;
			videoControls.visible = video.visible = true;
			identityVideo.removeEventListener(VideoEvent.COMPLETE, onComplete);
			callback();
		}
	identityVideo.addEventListener(VideoEvent.COMPLETE, onComplete);
}

public function showIdentityPhoto(event:String, url:String, link:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	identityPhoto.visible = true;
	identityPhoto.source = url;
	var identityPhotoTimer:Timer = new Timer(5000, 1);
	identityVideo.addEventListener(MouseEvent.CLICK, function():void{
			reportEvent(event=='before' ? 'preRollClick' : 'postRollClick');
			goToUrl(link);
		});
    identityPhotoTimer.addEventListener("timer", function():void {
			if(!identityPhoto.visible) return;
			identityPhoto.visible = false;
			videoControls.visible = video.visible = true;
			callback();
		});
    identityPhotoTimer.start();
}

public function handleIdentity(event:String, callback:Function):void {
	var type:String, url:String, text:String = '';
	currentIdentityEvent = event;
	if (event=='before') {
		switch (activeElement.get('beforeDownloadType')) {
			case 'video': showIdentityVideo('before', activeElement.getString('beforeDownloadUrl'), activeElement.getString('beforeLink'), callback); break;
			case 'photo': showIdentityPhoto('before', activeElement.getString('beforeDownloadUrl'), activeElement.getString('beforeLink'), callback); break;
			default: callback();
		}
	} else {
		var textCallback:Function = callback;
		text = new String(activeElement.get('afterText'));
		if (text.length>0) {
		   	textCallback = function():void {
				identityPanelText.htmlText = text;
				identityPanel.visible = true;
				identityPanel.onClose = callback;
		   	}
		}
		switch (activeElement.get('afterDownloadType')) {
			case 'video': showIdentityVideo('after', activeElement.getString('afterDownloadUrl'), activeElement.getString('afterLink'), textCallback); break;
			case 'photo': showIdentityPhoto('after', activeElement.getString('afterDownloadUrl'), activeElement.getString('afterLink'), textCallback); break;
			default: textCallback();
		}
	}
}