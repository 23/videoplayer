// ActionScript file
import mx.core.FlexGlobals;
import mx.core.UIComponent;
import mx.events.ResizeEvent;
import mx.utils.URLUtil;

[Bindable] public var props:HashCollection = new HashCollection();
private var prioritizeLiveStreams:Boolean = false;
public var propDefaults:Object = {
	backgroundColor: 'black',
	trayBackgroundColor: 'black',
	trayTextColor: 'white',
	trayFont: 'Helvetica, Arial, sans-serif',
	trayTitleFontSize: parseFloat('13'),
	trayTitleFontWeight: 'bold',
	trayContentFontSize: parseFloat('11'),
	trayContentFontWeight: 'normal',
	trayAlpha: parseFloat('0.8'),
	showTray: true,
	showDescriptions: true,
	logoSource: '',
	showBigPlay: true,
	showLogo: true,
	showShare: true,
	showBrowse: true,
	browseMode: false,
	logoPosition: 'top right',
	logoAlpha: parseFloat('0.7'),
	logoWidth: parseFloat('80'),
	logoHeight: parseFloat('40'),
	verticalPadding: parseFloat('0'),
	horizontalPadding: parseFloat('0'),
	trayTimeout: parseFloat('5000'),
	infoTimeout: parseFloat('5000'),
	recommendationHeadline: 'Also have a look at...',
	identityCountdown: false,
	identityAllowClose: true,
	identityCountdownTextSingular: "This advertisement will end in % second",
	identityCountdownTextPlural: "This advertisement will end in % seconds",
	recommendationMethod: 'channel-popular',
	lowBandwidthThresholdKbps: parseFloat('0'),
	maintainIdentityAspectRatio: true,
	enableSubtitles: true,
	subtitlesOnByDefault: false,
	subtitlesDesign: 'bars',
	playlistClickMode:'link',
	enableLiveStreams: true,
	playflowInstreamVideo: 'http://prototypes.labs.23company.com/bold.xml||',
	playflowInstreamOverlay: '|ca-video-googletest1|123',
	
	start: parseFloat('0'),
	player_id: parseFloat('0'),
	rssLink: '',
	podcastLink: '',
	embedCode: '',
	currentVideoEmbedCode: '',
	socialSharing: true,
	streaming: false,

	autoPlay: false,
	loop: false,
	playHD: false
}
private function initLoadURL():void{
	var domain:String = URLUtil.getServerName(FlexGlobals.topLevelApplication.url);
	if(domain=='localhost' || domain=='') domain=defaultDomain;
	var protocol:String = URLUtil.getProtocol(FlexGlobals.topLevelApplication.url);
	if(protocol!='https') protocol='http';
	props.put('domain', domain);
	props.put('site_url', protocol + '://' + domain);
	
	// Determine a load parameters
	var loadParameters:Array = new Array();
	var options:Array = ['photo_id', 'token', 'user_id', 'search', 'tag', 'tags', 'tag_mode', 'album_id', 'year', 'month', 'day', 'datemode', 'video_p', 'audio_p', 'video_encoded_p', 'order', 'orderby', 'p', 'size', 'rand', 'liveevent_id', 'liveevent_stream_id'];
	for (var i:int=0; i<options.length; i++) {
		var opt:String = options[i];
		if (FlexGlobals.topLevelApplication.parameters[opt]) {
			loadParameters.push(opt + '=' + encodeURI(FlexGlobals.topLevelApplication.parameters[opt]));
		}
	}
	if (defaultPhotoId.length) loadParameters.push('photo_id=' + encodeURI(defaultPhotoId)); 
	if (defaultAlbumId.length) loadParameters.push('album_id=' + encodeURI(defaultAlbumId));
	loadParameters.push('player_id=' + encodeURI(playerId));
	loadParameters.push('size=1');
	
	// Use load parameters to build JSON source
	var jsonSource:String = props.get('site_url') + '/api/photo/list?raw&format=json&' + loadParameters.join('&');
	props.put('jsonSource', jsonSource);
	
	// Mail link from parameters 
	props.put('mailLink', (props.get('socialSharing') ? "/send?popup_p=1&" + loadParameters.join('&') : ''));	
}
private function initProperties(settings:Object):void {
	// Load defaults
	for (name in propDefaults) {
		props.put(name, propDefaults[name]);
	}

	// Load settings from /js/video-settings?raw
	for (name in settings) {
		if (typeof(propDefaults[name])=='undefined') continue;
		// We enforce the same data type as the value in propDefaults
  		if (typeof propDefaults[name]=='boolean') {
		 	props.put(name, new Boolean(parseFloat(settings[name])));
	 	} else {	
  	    	if (isNaN(settings[name]) || name=='logoSource') {
		 		props.put(name, settings[name]);
  	    	} else {
			 	props.put(name, parseFloat(settings[name]));
  	    	}
  	    }
	}
	// Read from FlashVars
	for (name in propDefaults) {
	  	if(typeof(FlexGlobals.topLevelApplication.parameters[name])!='undefined') {
	  		if (typeof propDefaults[name]=='boolean') {
			 	props.put(name, new Boolean(parseFloat(FlexGlobals.topLevelApplication.parameters[name])));
		 	} else {	
	  	    	if (isNaN(FlexGlobals.topLevelApplication.parameters[name]) || name=='logoSource') {
			 		props.put(name, FlexGlobals.topLevelApplication.parameters[name]);
	  	    	} else {
				 	props.put(name, parseFloat(FlexGlobals.topLevelApplication.parameters[name]));
	  	    	}
	  	    }
	  	}
	}

	// Test logoSource
	if (props.get('logoSource')=='no logo' || props.get('logoSource')=='') {
		props.put('showLogo', false);
		props.put('logoSource', '');	
	}
	if(props.get('showLogo')) {
		var logoRequest:URLRequest = new URLRequest((props.get('logoSource') as String));
		var logoLoader:URLLoader = new URLLoader();
		logoLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
			props.put('logoSource', ''); props.put('showLogo', false);
		});
		logoLoader.addEventListener(IOErrorEvent.IO_ERROR, function httpStatusHandler(e:Event):void {
			props.put('logoSource', ''); props.put('showLogo', false);
		});
		logoLoader.load(logoRequest);
	}

	// Logo position
	var pos:String = props.get('logoPosition').toString();
	props.put('logoAlign', (new RegExp('left').test(pos) ? 'left' : 'right'));
	props.put('logoVAlign', (new RegExp('top').test(pos) ? 'top' : 'bottom'));

	// Tray and information timeout
	trayTimer.delay = props.getNumber('trayTimeout');
	trayTimer.reset();
	infoTimer.delay = props.getNumber('infoTimeout');
	infoTimer.reset();
	
	// Make the embed code current
	updateCurrentVideoEmbedCode();
	
	// If bandwidth or player doesn't allow h264 quality, we won't allow streaming
	if (!h264()) props.put('streaming', 0);
	
	// Should we start by playing HD? 
	if(props.get('playHD')) currentVideoFormat = 'video_hd';
	
	// Load up featured live streams
	if(props.get('enableLiveStreams')) {
		var streamOptions:Object = {};
		if (FlexGlobals.topLevelApplication.parameters['liveevent_id']) {
			prioritizeLiveStreams = true;
			streamOptions = {
				liveevent_id: FlexGlobals.topLevelApplication.parameters['liveevent_id'],
				token: (FlexGlobals.topLevelApplication.parameters['token'] ? FlexGlobals.topLevelApplication.parameters['token'] : '')
			}
		} else if (FlexGlobals.topLevelApplication.parameters['liveevent_stream_id']) {
			prioritizeLiveStreams = true;
			streamOptions = {
				liveevent_stream_id: FlexGlobals.topLevelApplication.parameters['liveevent_stream_id'],
				token: (FlexGlobals.topLevelApplication.parameters['token'] ? FlexGlobals.topLevelApplication.parameters['token'] : '')
			}
		} else {
			streamOptions = {featured_p:1};
		}
		liveStreamsMenu.options = [];
		liveStreamsMenu.value = null;
		try {
			doAPI('/api/liveevent/stream/list', streamOptions, function(s:Object):void{
				var streams:Array = s.streams;
				if(streams.length) {
					var streamMenu:Array = [];
					streams.forEach(function(stream:Object, i:int, ignore:Object):void{
						streamMenu.push({value:stream, label:stream.name});
					});
					liveStreamsMenu.options = streamMenu;
					
					if(prioritizeLiveStreams) {
						setActiveElementToLiveStream(streams[0], false);
					}
				} else {
					prioritizeLiveStreams = false;
				}
			});
		} catch(e:Error) {}
	}
}

private function getRecommendationSource():String {
	if(!context || !context.photos) return(props.get('site_url') + '/api/photo/list?raw&format=json&size=10');
	
	if(context.photos.length==1) {
		// There's only one video to play, we'll need to construct recommendation in another fashion.
		var recommendationSource:String;
		var method:String = new String(props.get('recommendationMethod'));
		switch (method) {
			case 'site-new':
			case 'channel-new':
				recommendationSource = props.get('site_url') + '/api/photo/list?raw&format=json&size=10&orderby=uploaded&order=desc';
				break;
			case 'site-popular':
			case 'channel-popular':
			case 'similar':
			default:
				recommendationSource = props.get('site_url') + '/api/photo/list?raw&format=json&size=10&orderby=rank&order=desc';
				break;
		}
		if (playerId.length) recommendationSource += '&player_id=' + encodeURI(playerId);
		if (context.photos[0].album_id!='' && (method=='channel-new' || method=='channel-popular')) recommendationSource += '&album_id=' + context.photos[0].album_id;
		return(recommendationSource);
	} else {
		return(new String(props.get('jsonSource')));
	}
}

private function updateCurrentVideoEmbedCode():void {
	try {
		var e:String = props.getString('embedCode');
		if (!e.match(/photo\%5fid/) && !e.match(/liveevent(\%5f|\%5fstream\%5f)\%5fid/)) {
			// remove album_id and token
			e = e.replace(new RegExp('(album\%5fid|token)=[a-zA-Z0-9]*\&?', 'img'), '');
			// set photo_id
			e = e.replace(new RegExp('FlashVars="'), 'FlashVars="photo\%5fid=' + activeElement.getString('photo_id') + '&');
			e = e.replace(new RegExp('FlashVars" value="', 'img'), 'FlashVars="photo\%5fid=' + activeElement.getString('photo_id') + '&');
		}
		props.put('currentVideoEmbedCode', e);
	} catch(err:ErrorEvent) {
		// A safety net for bad code
		props.put('currentVideoEmbedCode', props.getString('embedCode'));
	}  
}

private function bootstrapAds():void {
	// Clean up
	visualAdContainer.removeAllChildren();
	ads = null;
	
	// Is there advertising=
	if(activeElement.getString('playflowInstreamVideo').length==0 && activeElement.getString('playflowInstreamOverlay').length==0) return;
		
	// Attach VisualAd element to the stage, and make sure it's sized correctly
	ads = new VisualAds();
	visualAdContainer.addChild((ads as UIComponent));
	
	// Make sure it's sized correctly
	var fitSize:Function = function():void{
		ads.width = visualAdContainer.width;
		ads.height = visualAdContainer.height;
	}
	fitSize();
	visualAdContainer.addEventListener(ResizeEvent.RESIZE, fitSize);
	
	// Interface with the app through events
	ads.addEventListener('contentPauseRequested', function():void{
		forceHideTray = true;
		trayHide();
		video.pause();
	});
	ads.addEventListener('contentResumeRequested', function():void{
		forceHideTray = false;
		trayShow();
		video.play();	
	});
	
	// Append sources
	var a:Array;
	a = activeElement.getString('playflowInstreamVideo').split('|');
	if(a.length==3) ads.push('video', decodeURIComponent(a[0]), decodeURIComponent(a[1]), decodeURIComponent(a[2]));
	a = activeElement.getString('playflowInstreamOverlay').split('|');
	if(a.length==3) ads.push('overlay', decodeURIComponent(a[0]), decodeURIComponent(a[1]), decodeURIComponent(a[2]));
}