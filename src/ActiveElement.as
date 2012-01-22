import flash.events.ErrorEvent;
import mx.events.VideoEvent;
[Bindable] public var numVideoElements:int = 0;
[Bindable] public var currentElementIndex:int = 0;
[Bindable] public var activeElement:HashCollection = new HashCollection();
public var itemsArray: Array;
private var supportedFormats:Array = [];
[Bindable]public var currentVideoFormat:String = 'video_medium';
[Bindable] public var showBeforeIdentity:Boolean = false;
[Bindable] public var showVideoAd:Boolean = false;

private function initActiveElement():void {
	resetActiveElement();
}
 
private function resetActiveElement(skip:Boolean=false):void {
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
	activeElement.put('live', false);
	
	// Reset other stuff related to the active video
	clearVideo();
	identityVideo.visible = false;
	identityVideo.close();
	showBeforeIdentity = true;
	showVideoAd = true;
	liveStreamsMenu.value = null;

	if(!skip) {
		progress.setSections([]);
		subtitles.suppportedLocales = {}; subtitlesMenu.options = [];
	}
}

private function setActiveElementToLiveStream(stream:Object, startPlaying:Boolean=false):void {
	resetActiveElement();

	// Handle video title and description
	var title:String = stream.name.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
	activeElement.put('video_p', true);
	activeElement.put('photo_id', stream.liveevent_stream_id);
	activeElement.put('title', title);
	activeElement.put('content', "");
	activeElement.put('hasInfo', false);
	activeElement.put('link', stream.one);
	activeElement.put('length', 0); 
	activeElement.put('start', 0);
	activeElement.put('skip', false);
	activeElement.put('live', true);
	activeElement.put('one', props.get('site_url') + stream.one); 
	supportedFormats = ['live'];
	formatsMenu.options = [];
	activeElement.put('photoSource', props.get('site_url') + stream.large_download);
	activeElement.put('videoSource', stream.rtmp_stream);
	video.source = getFullVideoSource();
	
	showVideoElement();
	if(startPlaying) playVideoElement();

	// Aspect ratios
	activeElement.put('aspectRatio', stream.thumbnail_large_aspect_ratio*1.0);
	video.aspectRatio = identityVideo.aspectRatio = 0;
	
	// Make embed code current
	updateCurrentVideoEmbedCode();
	
	// We want the tray and possible the info box to show up when a new element starts playing
	infoShow();
	trayShow();
	
	// Note that we've loaded the video 
	reportEvent('load');

}

private function setActiveElement(i:int, startPlaying:Boolean=false, start:Number=0, skip:int=0, format:String=null):Boolean {
	if (!context || !context.photos || !context.photos[i]) return(false);
	resetActiveElement(skip);

	numVideoElements = context.photos.length;
	currentElementIndex = i;
	var o:Object = context.photos[i];
  	var video_p:Boolean = new Boolean(parseInt(o.video_p)) && new Boolean(parseInt(o.video_encoded_p));
  	activeElement.put('video_p', video_p);
  	
  	// Handle video title and description
  	var title:String = o.title.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
  	var content:String = o.content_text.replace(new RegExp('(<([^>]+)>)', 'ig'), '');
	var hasInfo:Boolean =  (title.length>0 || content.length>0);
  	activeElement.put('photo_id', o.photo_id);
  	activeElement.put('title', title);
  	activeElement.put('content', content);
  	activeElement.put('hasInfo', hasInfo);
  	activeElement.put('link', o.one);
  	activeElement.put('length', o.video_length); 
  	activeElement.put('start', start);
  	activeElement.put('skip', skip);

	// PlayFlow
	activeElement.put('beforeDownloadType', o.before_download_type);
	activeElement.put('beforeDownloadUrl', props.get('site_url') + o.before_download_url.replace(new RegExp('video_small', 'img'), (h264() ? 'video_medium' : 'video_small')));
	activeElement.put('beforeLink', o.before_link); 
	activeElement.put('afterDownloadType', o.after_download_type); 
	activeElement.put('afterDownloadUrl', props.get('site_url') + o.after_download_url.replace(new RegExp('video_small', 'img'), (h264() ? 'video_medium' : 'video_small')));
	activeElement.put('afterLink', o.after_link);
	activeElement.put('afterText', o.after_text); 
	
	// Add VAST 2.0 and Google InStream support
	activeElement.put('playflowInstreamVideo', o.playflow_instream_video||props.getString('playflowInstreamVideo'));
	activeElement.put('playflowInstreamOverlay', o.playflow_instream_overlay||props.getString('playflowInstreamOverlay'));
	bootstrapAds();

	// Photo source
	activeElement.put('photoSource', props.get('site_url') + o.large_download);
	activeElement.put('photoWidth', new Number(o.large_width));
	activeElement.put('photoHeight', new Number(o.large_height));
	
	// Aspect ratios
	var ar:Number = parseInt(o.large_width) / parseInt(o.large_height);
	activeElement.put('aspectRatio', ar);
	video.aspectRatio = ar;
	identityVideo.aspectRatio = (props.getBoolean('maintainIdentityAspectRatio') ? 0 : ar);
	showImageElement();
	
	// Link back to the video
	activeElement.put('one', props.get('site_url') + o.one); 
	
	if(video_p) {
		image.source = null;
		showVideoElement();
	} else {
		showImageElement();
	}
	
	// Get sections and show, otherwise reset
	if(!skip) {
		if(o.subtitles_p && props.get('enableSubtitles')) {
			try {
				doAPI('/api/photo/subtitle/list', {photo_id:o.photo_id, token:o.token, subtitle_format:'json', stripped_p:'1'}, function(sub:Object):void{
					var locales:Object = {};
					var defaultLocale:String = '';
					var localeMenu:Array = [];
					localeMenu.push({value:'', label:'No subtitles'});
					for (var i:int=0; i<sub.subtitles.length; i++) {
						locales[sub.subtitles[i].locale] = {href:props.get('site_url') + sub.subtitles[i].href, language:sub.subtitles[i].language, locale:sub.subtitles[i].locale};
						localeMenu.push({value:sub.subtitles[i].locale, label:sub.subtitles[i].language});
						if(sub.subtitles[i].default_p) defaultLocale = sub.subtitles[i].locale; 
					}
					// Let the subtitles component know about this
					subtitles.suppportedLocales = locales;
					subtitles.locale = (props.get('subtitlesOnByDefault') ? defaultLocale : '');
					// Create a menu from the same options
					subtitlesMenu.options = localeMenu;
					subtitlesMenu.value = subtitles.locale;
				});
			} catch(e:Error) {subtitles.suppportedLocales = {}; subtitlesMenu.options = [];}
		} else {
			subtitles.suppportedLocales = {}; subtitlesMenu.options = [];
		}
	
		// Get subtitles and show, otherwise reset
		if(o.sections_p) {
			try {
				doAPI('/api/photo/section/list', {photo_id:o.photo_id, token:o.token}, function(sec:Object):void{progress.setSections(sec.sections);});
			} catch(e:Error) {progress.setSections([]);}
		} else {
			progress.setSections([]);
		}
	}

	// Supported formats, default format and build menu
	if(!skip) prepareSupportedFormats(o);
	// Switch to format if needed
	setVideoFormat(format || currentVideoFormat);
	
 	if(video_p) {
  		if (props.get('autoPlay') || props.get('loop') || startPlaying) playVideoElement();
  	}

	// Make embed code current
	updateCurrentVideoEmbedCode();

	// We want the tray and possible the info box to show up when a new element starts playing
	infoShow();
	trayShow();

	// Note that we've loaded the video 
	reportEvent('load');

	return(true);
} 	

private function prepareSupportedFormats(o:Object):void {
	// Reset list
	supportedFormats = [];

	// Build list of supported formats and their URLs
	if (!h264() && typeof(o.video_small_download)!='undefined'&&o.video_small_download.length>0) {
		supportedFormats.push({format:'video_small', pseudo:false, label: 'Low (180p)', source:props.get('site_url') + o.video_small_download});
	}
	if (h264()&&typeof(o.video_mobile_high_download)!='undefined'&&o.video_mobile_high_download.length>0) {
		supportedFormats.push({format:'video_mobile_high', pseudo:true, label: 'Low (180p)', source:props.get('site_url') + o.video_mobile_high_download}); 
	}
	if (h264()&&typeof(o.video_medium_download)!='undefined'&&o.video_medium_download.length>0) {
		supportedFormats.push({format:'video_medium', pseudo:true, label: 'Standard (360p)', source:props.get('site_url') + o.video_medium_download}); 
	}
	if (h264()&&typeof(o.video_hd_download)!='undefined'&&o.video_hd_download.length>0) {
		supportedFormats.push({format:'video_hd', pseudo:true, label: 'HD (720p)', source:props.get('site_url') + o.video_hd_download}); 
	}
	if (h264()&&typeof(o.video_1080p_download)!='undefined'&&o.video_1080p_download.length>0&&o.video_1080p_size>0) {
		supportedFormats.push({format:'video_1080p', pseudo:true, label: 'Full HD (1080p)', source:props.get('site_url') + o.video_1080p_download}); 
	}
	
	// We'll want a menu for this
	var _formats:Array = [];
	for (var i:Object in supportedFormats) {
		_formats.push({value:supportedFormats[i].format, label:supportedFormats[i].label});
	}
	formatsMenu.options = _formats;	
}
public function setVideoFormat(format:String):void {
	var o:Object = null;
	for (var i:Object in supportedFormats) {
		if(supportedFormats[i].format==format) {
			o = supportedFormats[i];
			continue;
		}
	}
	if(!o) o=supportedFormats[supportedFormats.length-1];
	if(!o.pseudo) activeElement.put('start', 0);
	activeElement.put('videoSource', o.source);
	currentVideoFormat = o.format;
}

public function switchVideoFormat(format:String):void {
	setActiveElement(currentElementIndex, true, video.playheadTime+activeElement.getNumber('start'), 1, format);
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
		item.photoSource = props.get('site_url') + o.quad75_download;
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
	videoControls.visible=true;
	progress.visible=(!video.isLive);
	
	image.source = activeElement.get('photoSource');
	image.visible=true;
}

public function playVideoElement():void {
	if(!activeElement.get('video_p')) return;
	if(video.completed) {
		activeElement.put('start', 0);
		video.playheadTime = 0;		
	}
	image.visible=false;
	video.visible=true;
	videoControls.visible=true;
	progress.visible=(!video.isLive);
	video.source = getFullVideoSource();
	if(showVideoAd&&ads&&ads.preroll()) {
		showVideoAd = false;
		return;
	}
	if(showBeforeIdentity) {
		video.stop();
		video.pause();
		// We'll only do this once for every element, otherwise the preroll will start on every pause/play.
		showBeforeIdentity = false;
		handleIdentity('before', function():void {playVideoElement();});
		return;
	}
	video.play();	
}
private function pauseVideoElement():void {
	try {
		video.pause();
	}catch(e:ErrorEvent){}
}

private function getFullVideoSource():String {
	var joinChar:String = (/\?/.test(activeElement.getString('videoSource')) ? '&' : '?');
	return(activeElement.getString('videoSource') + joinChar + 'start=' + encodeURIComponent(activeElement.getString('start')) + '&skip=' + encodeURIComponent(activeElement.getString('skip')));
}            

