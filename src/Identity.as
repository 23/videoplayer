import flash.utils.Timer;

import mx.events.VideoEvent;

public function showIdentityVideo(url:String, link:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	infoHide();
	identityVideo.visible = true;
	identityVideo.source = url;
	identityVideo.play();
	clickTarget = link;
	var onComplete:Function = function():void {
			if(!identityVideo.visible) return;
			infoShow();
			identityVideo.visible = false;
			videoControls.visible = video.visible = true;
			clickTarget = activeElement.getString('one');
			identityVideo.removeEventListener(VideoEvent.COMPLETE, onComplete);
			callback();
		}
	identityVideo.addEventListener(VideoEvent.COMPLETE, onComplete);
}

public function showIdentityPhoto(url:String, link:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	identityPhoto.visible = true;
	identityPhoto.source = url;
	var identityPhotoTimer:Timer = new Timer(5000, 1);
	clickTarget = link;
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
	if (event=='before') {
		switch (activeElement.get('beforeDownloadType')) {
			case 'video': showIdentityVideo(activeElement.getString('beforeDownloadUrl'), activeElement.getString('beforeLink'), callback); break;
			case 'photo': showIdentityPhoto(activeElement.getString('beforeDownloadUrl'), activeElement.getString('beforeLink'), callback); break;
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
			case 'video': showIdentityVideo(activeElement.getString('afterDownloadUrl'), activeElement.getString('afterLink'), textCallback); break;
			case 'photo': showIdentityPhoto(activeElement.getString('afterDownloadUrl'), activeElement.getString('afterLink'), textCallback); break;
			default: textCallback();
		}
	}
}