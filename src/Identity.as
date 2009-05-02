import flash.utils.Timer;

public function showIdentityVideo(url:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	identityVideo.visible = true;
	identityVideo.source = url;
	identityVideo.play();
	identityVideo.addEventListener(VideoEvent.COMPLETE, function():void {
			if(!identityVideo.visible) return;
			identityVideo.visible = false;
			videoControls.visible = video.visible = true;
			callback();
		});
}

public function showIdentityPhoto(url:String, callback:Function):void {
	videoControls.visible = video.visible = false;
	identityPhoto.visible = true;
	identityPhoto.source = url;
	var identityPhotoTimer:Timer = new Timer(5000, 1);
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
			case 'video': showIdentityVideo(new String(activeElement.get('beforeDownloadUrl')), callback); break;
			case 'photo': showIdentityPhoto(new String(activeElement.get('beforeDownloadUrl')), callback); break;
			default: callback();
		}
	} else {
		var textCallback:Function = callback;
		text = new String(activeElement.get('afterText'));
		if (text.length>0) {
		   	textCallback = function():void {
				textPanel.text = text;
				textPanel.visible = true;
				textPanel.showShare = props.get('showShare');
				textPanel.onClose = callback;
		   	}
		}
		switch (activeElement.get('afterDownloadType')) {
			case 'video': showIdentityVideo(new String(activeElement.get('afterDownloadUrl')), textCallback); break;
			case 'photo': showIdentityPhoto(new String(activeElement.get('afterDownloadUrl')), textCallback); break;
			default: textCallback();
		}
	}
}