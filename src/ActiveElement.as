import mx.core.Application;
[Bindable] public var numElements:int = 0;
[Bindable] public var currentElementIndex:int = 0;
[Bindable] public var activeElement:HashCollection = new HashCollection();
public var itemsArray: Array;
[Bindable] public var playHD:Boolean = false; 

private function initActiveElement():void {
	trace("initActiveElement");
	resetActiveElement();
}
 
private function resetActiveElement():void {
  	activeElement.put('video_p', false);
  	activeElement.put('title', '');
  	activeElement.put('content', '');
  	activeElement.put('link', '');
  	activeElement.put('videoSource', '');
  	activeElement.put('photoSource', '');
  	activeElement.put('photoWidth', new Number(0));
  	activeElement.put('photoHeight', new Number(0));
  	activeElement.put('aspectRatio', new Number(1));
}

private function setActiveElement(i:int, startPlaying:Boolean=false):Boolean {
	trace("setActiveElement " + i);
	if (!context || !context.photos || !context.photos[i]) return(false);
	numElements = context.photos.length;
	currentElementIndex = i;
	trace("numElements " + numElements);
	trace("currentElementIndex " + currentElementIndex);
	var o:Object = context.photos[i];
  	var video_p:Boolean = new Boolean(parseInt(o.video_p)) && new Boolean(parseInt(o.video_encoded_p));
  	activeElement.put('video_p', video_p);
  	
  	// Handle video title and description
  	var title:String = o.title.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
  	var content:String = o.content_text.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
  	var hasInfo:Boolean =  (props.get('showDescriptions') && (title.length>0 || content.length>0));
  	activeElement.put('title', title);
  	activeElement.put('content', content);
  	activeElement.put('hasInfo', hasInfo);
  	activeElement.put('link', o.one);

	var hasHD:Boolean = (h264()&&typeof(o.video_hd_download)!='undefined'&&o.video_hd_download.length>0);
	activeElement.put('hasHD', hasHD);

	// Video source, including referer, depending on flash version and HD context
	var videoSource:String = 'http://' + props.get('domain') + (h264()&&typeof(o.video_medium_download)!='undefined' ? o.video_medium_download : o.video_small_download);
	if (hasHD && playHD) videoSource = 'http://' + props.get('domain') + o.video_hd_download;
  	videoSource += '?_referer='+encodeURIComponent(referer());
  	activeElement.put('videoSource', videoSource);
  	
  	// Photo source with referer
  	var photoSource:String = 'http://' + props.get('domain') + o.large_download;
  	photoSource += '?_referer='+encodeURIComponent(referer());
  	activeElement.put('photoSource', photoSource);

  	activeElement.put('photoWidth', new Number(o.large_width));
  	activeElement.put('photoHeight', new Number(o.large_height));
  	activeElement.put('aspectRatio', parseInt(o.large_width) / parseInt(o.large_height));
 
 	if(video_p) {
 		image.source = null;
  		showVideoElement();
  		if (props.get('autoPlay') || startPlaying) playVideoElement();
  	} else {
  		showImageElement();
  	}

	// We want the tray and possible the info box to show up when a new element starts playing
	infoShow();
	trayShow();

	return(true);
} 	

private function createItemsArray() : Array {
	itemsArray = new Array();
	for(var i:Number = 0 ; i < context.photos.length; i++) {
		var o:Object = context.photos[i];
		var item : Object = new Object();
		item.itemID = i;		
		item.photoSource = 'http://' + props.get('domain') + o.large_download;
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

private function previousElement():Boolean {if(video.playing) video.stop(); return(setActiveElement(currentElementIndex-1));}
private function nextElement():Boolean {if(video.playing) video.stop(); return(setActiveElement(currentElementIndex+1));}
private function setElementByID(id:Number):void {
	if(video.playing) video.stop();
	setActiveElement(id);
}

private function showImageElement():void {
	if(video.playing) video.stop();
	
	video.visible=false;
	videoControls.visible=false;
	
	image.visible=true;
}
private function showVideoElement():void {
	video.visible=false;
	videoControls.visible=true;
	
	image.source = activeElement.get('photoSource');
	image.visible=true;
}
private function playVideoElement():void {
	if(!activeElement.get('video_p')) return;
	video.visible=true;
	videoControls.visible=true;
	image.visible=false;
	video.play();
}
private function pauseVideoElement():void {
	playVideoElement();
	video.pause();
}

