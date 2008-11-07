
import flash.events.ErrorEvent;
[Bindable] public var numElements:int = 0;
[Bindable] public var currentElementIndex:int = 0;
[Bindable] public var activeElement:HashCollection = new HashCollection()

private function initActiveElement():void {
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

private function setActiveElement(i:int):void {
	if (!context || !context.photos || !context.photos[i]) return;
	numElements = context.photos.length;
	currentElementIndex = i;
	var o:Object = context.photos[i];
  	var video_p:Boolean = new Boolean(parseInt(o.video_p)) && new Boolean(parseInt(o.video_encoded_p));
  	activeElement.put('video_p', video_p);
  	if (o.content_text.length && !o.title.length) {o.title=o.content_text; o.content_text='';} 
  	activeElement.put('title', o.title);
  	activeElement.put('content', o.content_text);
  	activeElement.put('link', o.one);
  	activeElement.put('videoSource', 'http://' + props.get('domain') + (h264()&&typeof(o.video_medium_download)!='undefined' ? o.video_medium_download : o.video_small_download));
  	activeElement.put('photoSource', 'http://' + props.get('domain') + o.large_download);
  	activeElement.put('photoWidth', new Number(o.large_width));
  	activeElement.put('photoHeight', new Number(o.large_height));
  	activeElement.put('aspectRatio', parseInt(o.large_width) / parseInt(o.large_height));
 
 	if(props.get('trayTitleTextTranform')=='uppercase') o.title = o.title.toUpperCase();
	if(props.get('trayTitleTextTranform')=='lowercase') o.title = o.title.toLowerCase();
	if(props.get('trayContentTextTranform')=='uppercase') o.content = o.content.toUpperCase();
	if(props.get('trayContentTextTranform')=='lowercase') o.content = o.content.toLowerCase();

 	if(video_p) {
  		showVideoElement();
  		if (props.get('autoPlay')) playVideoElement();
  	} else {
  		showImageElement();
  	}  	
} 	

private function previousElement():void {if(video.playing) video.stop(); setActiveElement(currentElementIndex-1);}
private function nextElement():void {if(video.playing) video.stop(); setActiveElement(currentElementIndex+1);}

private function showImageElement():void {
	if(video.playing) video.stop();
	video.visible=false;
	videoControls.visible=false;
	videoTime.visible=false;
	videoProgress.visible=false;
	bigPlay.visible=false;
	image.visible=true;
}
private function showVideoElement():void {
	video.visible=false;
	videoControls.visible=true;
	videoTime.visible=true;
	videoProgress.visible=true;
	bigPlay.visible=true;
	image.visible=true;
}
private function playVideoElement():void {
	if(!activeElement.get('video_p')) return;
	video.visible=true;
	videoControls.visible=true;
	videoTime.visible=true;
	videoProgress.visible=true;
	bigPlay.visible=false;
	image.visible=false;
	video.play();
}
private function pauseVideoElement():void {
	playVideoElement();
	video.pause();
	bigPlay.visible=true;
}

