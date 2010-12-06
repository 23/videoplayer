[Bindable] public var numVideoElements:int = 0;
[Bindable] public var currentElementIndex:int = 0;
[Bindable] public var activeElement:HashCollection = new HashCollection();
public var itemsArray: Array;
[Bindable] public var playHD:Boolean = false;
[Bindable] public var showBeforeIdentity:Boolean = false; 

private function initActiveElement():void {
	resetActiveElement();
}
 
private function resetActiveElement():void {
  	activeElement.put('photo_id', '');
	activeElement.put('video_p', false);
  	activeElement.put('title', '');
  	activeElement.put('content', '');
  	activeElement.put('link', '');
  	activeElement.put('videoSource', '');
  	activeElement.put('photoSource', '');
  	activeElement.put('photoWidth', new Number(0));
  	activeElement.put('photoHeight', new Number(0));
  	activeElement.put('aspectRatio', new Number(1));
	activeElement.put('beforeDownloadType', ''); 
	activeElement.put('beforeDownloadUrl', '');
	activeElement.put('beforeLink', ''); 
	activeElement.put('afterDownloadType', ''); 
	activeElement.put('afterDownloadUrl', ''); 
	activeElement.put('afterLink', ''); 
	activeElement.put('afterText', '');
	activeElement.put('length', '0');
	activeElement.put('start', '0');
	activeElement.put('skip', '0');
}

private function setActiveElement(i:int, startPlaying:Boolean=false, start:Number=0, skip:int=0):Boolean {
	if (!context || !context.photos || !context.photos[i]) return(false);
	clearVideo();
	identityVideo.visible = false;
	identityVideo.close();
	showBeforeIdentity = true;
	numVideoElements = context.photos.length;
	currentElementIndex = i;
	var o:Object = context.photos[i];
  	var video_p:Boolean = new Boolean(parseInt(o.video_p)) && new Boolean(parseInt(o.video_encoded_p));
  	activeElement.put('video_p', video_p);
  	
  	// Handle video title and description
  	var title:String = o.title.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
  	var content:String = o.content_text.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
  	var hasInfo:Boolean =  (props.get('showDescriptions') && (title.length>0 || content.length>0));
  	activeElement.put('photo_id', o.photo_id);
  	activeElement.put('title', title);
  	activeElement.put('content', content);
  	activeElement.put('hasInfo', hasInfo);
  	activeElement.put('link', o.one);
  	activeElement.put('length', o.video_length); 
  	activeElement.put('start', start);
  	activeElement.put('skip', skip);

	activeElement.put('beforeDownloadType', o.before_download_type);
	activeElement.put('beforeDownloadUrl', 'http://' + props.get('domain') + o.before_download_url.replace(new RegExp('video_small', 'img'), (h264() ? 'video_medium' : 'video_small')));
	activeElement.put('beforeLink', o.before_link); 
	activeElement.put('afterDownloadType', o.after_download_type); 
	activeElement.put('afterDownloadUrl', 'http://' + props.get('domain') + o.after_download_url.replace(new RegExp('video_small', 'img'), (h264() ? 'video_medium' : 'video_small')));
	activeElement.put('afterLink', o.after_link);
	activeElement.put('afterText', o.after_text); 
	
	// Get sections and show, otherwise reset
	if(o.sections_p) {
		try {
			doAPI('/api/photo/section/list', {photo_id:o.photo_id, token:o.token}, function(sec:Object):void{progress.setSections(sec.sections);});
		} catch(e:Error) {progress.setSections([]);}
	} else {
		progress.setSections([]);
	}

	activeElement.put('one', 'http://' + props.get('domain') + o.one); 
	clickTarget = activeElement.getString('one');

	var hasHD:Boolean = (h264()&&typeof(o.video_hd_download)!='undefined'&&o.video_hd_download.length>0);
	activeElement.put('hasHD', hasHD);

	// Video source depending on flash version and HD context
	var videoSource:String = 'http://' + props.get('domain') + (h264()&&typeof(o.video_medium_download)!='undefined' ? o.video_medium_download : o.video_small_download);
	if (hasHD && playHD) videoSource = 'http://' + props.get('domain') + o.video_hd_download;
  	activeElement.put('videoSource', videoSource);
  	
  	// Photo source
  	activeElement.put('photoSource', 'http://' + props.get('domain') + o.large_download);

  	activeElement.put('photoWidth', new Number(o.large_width));
  	activeElement.put('photoHeight', new Number(o.large_height));
  	activeElement.put('aspectRatio', parseInt(o.large_width) / parseInt(o.large_height));
 
 	if(video_p) {
 		image.source = null;
  		showVideoElement();
  		if (props.get('autoPlay') || props.get('loop') || startPlaying) playVideoElement();
  	} else {
  		showImageElement();
  	}

	// Make embed code current
	updateCurrentVideoEmbedCode();

	// We want the tray and possible the info box to show up when a new element starts playing
	infoShow();
	trayShow();

	return(true);
} 	

private function goToActiveElement():void {
	goToUrl(activeElement.get('one') as String);
}

private function createItemsArray(p:Object) : Array {
	itemsArray = new Array();
	if (!p.photos) return(itemsArray);
	for(var i:Number = 0 ; i < p.photos.length; i++) {
		var o:Object = p.photos[i];
		var item : Object = new Object();
		item.itemID = i;		
		item.photoSource = 'http://' + props.get('domain') + o.quad75_download;
		item.videoSource = 'http://' + props.get('domain') + (h264()&&typeof(o.video_medium_download)!='undefined' ? o.video_medium_download : o.video_small_download);
		item.photoWidth = new Number(o.large_width);
		item.photoHeight = new Number(o.large_height);
		item.aspectRatio = parseInt(o.large_width) / parseInt(o.large_height);
		//if (o.content_text.length && !o.title.length) {o.title=o.content_text; o.content_text='';} 
		item.title = o.title.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
		itemsArray.push(item);
	}
	return itemsArray;
}

private function clearVideo():void {
	video.source = null; video.visible = false;
	image.source = null; image.visible = false;
	if(identityVideo.playing) {identityVideo.stop(); identityVideo.dispatchEvent(new Event('complete', true));}
    if(video.playing) {video.stop(); video.close();}
}
private function previousElement():Boolean {
	return(setActiveElement(currentElementIndex-1));
}
private function nextElement():Boolean {
	return(setActiveElement(currentElementIndex+1));
}
private function setElementByID(id:Number, startPlaying:Boolean=false):void {
	clearVideo(); 
	setActiveElement(id, startPlaying);
}

private function showImageElement():void {
	clearVideo(); 
	
	video.visible=false;
	videoControls.visible=progress.visible=false;
	
	image.visible=true;
}
private function showVideoElement():void {
	video.visible=false;
	videoControls.visible=progress.visible=true;
	
	image.source = activeElement.get('photoSource');
	image.visible=true;
}

public function playVideoElement():void {
	if(!activeElement.get('video_p')) return;
	image.visible=false;
	video.visible=true;
	videoControls.visible=progress.visible=true;
	video.source = getFullVideoSource();
	if(showBeforeIdentity) {
		// For some reason, this seems to trigger pre-buffering of the video; which is good.
		video.play();
		video.pause();
		// We'll only do this once for every element, otherwise the preroll will start on every pause/play.
		showBeforeIdentity = false;
		handleIdentity('before', function():void {playVideoElement();});
		return;
	}
	video.play();
}
private function pauseVideoElement():void {
	playVideoElement();
	video.pause();
}

private function getFullVideoSource():String {
	return(activeElement.getString('videoSource') + '?start=' + encodeURIComponent(activeElement.getString('start')) + '&skip=' + encodeURIComponent(activeElement.getString('skip')));
}            

