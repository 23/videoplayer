// ActionScript file
import mx.core.FlexGlobals;
import mx.utils.URLUtil;

[Bindable] public var props:HashCollection = new HashCollection()
public var propDefaults:Object = {
	backgroundColor: 'black',
	trayBackgroundColor: 'white',
	trayTextColor: 'black',
	trayFont: 'TheSans, Helvetica, Arial, sans-serif',
	trayTitleFontSize: parseFloat('24'),
	trayTitleFontWeight: 'normal',
	trayContentFontSize: parseFloat('13'),
	trayContentFontWeight: 'normal',
	trayAlpha: parseFloat('0.7'),
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
private function initProperties(settings:Object):void {
	var loadParameters:Array = new Array();
	var loadSettings:Array = new Array();

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
	  		if(name!='showDescriptions' && name!='autoPlay') loadSettings.push(name + '=' + encodeURI(FlexGlobals.topLevelApplication.parameters[name]));
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

	// Determine a load parameters
	var domain:String = URLUtil.getServerName(FlexGlobals.topLevelApplication.url);
	if(domain=='localhost' || domain=='') domain=defaultDomain;
	props.put('domain', domain);
    var options:Array = ['photo_id', 'token', 'user_id', 'search', 'tag', 'tags', 'tag_mode', 'album_id', 'year', 'month', 'day', 'datemode', 'video_p', 'audio_p', 'video_encoded_p', 'order', 'orderby', 'p', 'size', 'rand'];
    for (var i:int=0; i<options.length; i++) {
		var opt:String = options[i];
		if (FlexGlobals.topLevelApplication.parameters[opt]) {
			loadParameters.push(opt + '=' + encodeURI(FlexGlobals.topLevelApplication.parameters[opt]));
			loadSettings.push(opt + '=' + encodeURI(FlexGlobals.topLevelApplication.parameters[opt]));
		}
    }
	if (defaultPhotoId.length) loadParameters.push('photo_id=' + encodeURI(defaultPhotoId)); 
	if (defaultAlbumId.length) loadParameters.push('album_id=' + encodeURI(defaultAlbumId));
	loadParameters.push('player_id=' + encodeURI(playerId));

	// Use load parameters to build JSON source
	var jsonSource:String = 'http://' + domain + '/api/photo/list?raw&format=json&' + loadParameters.join('&');
	props.put('jsonSource', jsonSource);
	
	// Mail link from parameters 
	props.put('mailLink', (props.get('socialSharing') ? "/send?popup_p=1&" + loadParameters.join('&') : ''));

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
}

private function getRecommendationSource():String {
	var domain:String = new String(props.get('domain'));
	if(!context || !context.photos) return('http://' + domain + '/api/photo/list?raw&format=json&size=20');
	
	if(context.photos.length==1) {
		// There's only one video to play, we'll need to construct recommendation in another fashion.
		var recommendationSource:String;
		var method:String = new String(props.get('recommendationMethod'));
		switch (method) {
			case 'site-new':
			case 'channel-new':
				recommendationSource = 'http://' + domain + '/api/photo/list?raw&format=json&size=20&orderby=uploaded&order=desc';
				break;
			case 'site-popular':
			case 'channel-popular':
			case 'similar':
			default:
				recommendationSource = 'http://' + domain + '/api/photo/list?raw&format=json&size=20&orderby=rank&order=desc';
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
		if (!e.match(/photo\%5fid/)) {
			// remove album_id and token
			e = e.replace(new RegExp('(album\%5fid|token)=[a-zA-Z0-9]*', 'img'), '');
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