import mx.core.Application;
[Bindable] public var numElements:int = 0;
[Bindable] public var currentElementIndex:int = 0;
[Bindable] public var activeElement:HashCollection = new HashCollection();
public var itemsArray : Array;

public function referer():String {
	return(Application.application.url);
}
			
public function h264():Boolean {
	var re:RegExp = new RegExp('([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)', 'img');
	var v:Array = re.exec(Capabilities.version);
	if (v[1]>9) {return(true);}
	if (v[1]==9 && (v[2]>0 || v[3]>=115)) {return(true);}
	return(false);
}

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

private function setActiveElement(i:int, playHD:Boolean):void {
	trace("setActiveElement");
	if(typeof(playHD)=='undefined') playHD = false;
	if (!context || !context.photos || !context.photos[i]) return;
	numElements = context.photos.length;
	currentElementIndex = i;
	var o:Object = context.photos[i];
  	var video_p:Boolean = new Boolean(parseInt(o.video_p)) && new Boolean(parseInt(o.video_encoded_p));
  	activeElement.put('video_p', video_p);
  	if (o.content_text.length && !o.title.length) {o.title=o.content_text; o.content_text='';} 
  	activeElement.put('title', o.title.replace(new RegExp('(<([^>]+)>)', 'ig'), ''));
  	activeElement.put('content', o.content_text.replace(new RegExp('(<([^>]+)>)', 'ig'), ''));
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
 
 	if(props.get('trayTitleTextTranform')=='uppercase') o.title = o.title.toUpperCase();
	if(props.get('trayTitleTextTranform')=='lowercase') o.title = o.title.toLowerCase();
	if(props.get('trayContentTextTranform')=='uppercase') o.content = o.content.toUpperCase();
	if(props.get('trayContentTextTranform')=='lowercase') o.content = o.content.toLowerCase();
	
 	if(video_p) {
 		image.source = null;
  		showVideoElement();
  		if (props.get('autoPlay')) playVideoElement();
  	} else {
  		showImageElement();
  	}

	var swfUrl:String = Application.application.loaderInfo.url;
	var urlStart:Number = swfUrl.indexOf("://")+3;
	var urlEnd:Number = swfUrl.indexOf("/", urlStart);
	var domain:String = swfUrl.substring(urlStart, urlEnd);		
  	embedPanel.embedTextValue = (Application.application.parameters.album_id == undefined) ? "<embed width='"+Application.application.width+"' height='"+Application.application.height+"' src='"+swfUrl+"' allowfullscreen='true' allowscriptaccess='always' flashvars='photo_id="+o.photo_id+"'/>" : "<embed width='"+Application.application.width+"' height='"+Application.application.height+"' src='"+swfUrl+"' allowfullscreen='true' allowscriptaccess='always' flashvars='album_id="+Application.application.parameters.album_id+"'/>";
	embedPanel.podcastLink = "itpc://"+domain+"/podcast/";
	embedPanel.rssLink = "http://"+domain+"/rss/";
	embedPanel.mailLink = "http://"+domain+"/send?popup_p=1&photo_id="+o.photo_id;
	
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

private function previousElement():void {if(video.playing) video.stop(); setActiveElement(currentElementIndex-1,false);}
private function nextElement():void {if(video.playing) video.stop(); setActiveElement(currentElementIndex+1,false);}
private function setElementByID(id:Number):void {
	if(video.playing) video.stop();
	setActiveElement(id, false);
}

private function showImageElement():void {
	if(video.playing) video.stop();
	
	video.visible=false;
	videoControls.visible=false;
	videoTime.visible=false;
	videoProgress.visible=false;
	progressBg.visible = false;
	
	image.visible=true;
}
private function showVideoElement():void {
	hdEnable();
	video.visible=false;
	videoControls.visible=true;
//	videoTime.visible=true;
	videoProgress.visible=true;
	progressBg.visible = true;
	
	image.source = activeElement.get('photoSource');
	image.visible=true;
}
private function playVideoElement():void {
	if(!activeElement.get('video_p')) return;
	video.visible=true;
	videoControls.visible=true;
	videoTime.x = videoProgress.x - videoTime.width/2;
	videoTime.visible=true;
	videoProgress.visible=true;
	progressBg.visible = true;
	image.visible=false;
	video.play();
}
private function pauseVideoElement():void {
	playVideoElement();
	video.pause();
}

