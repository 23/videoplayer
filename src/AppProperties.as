// ActionScript file
import mx.utils.URLUtil;
[Bindable] public var props:HashCollection = new HashCollection()
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
	logoSource: 'no logo',
	showLogo: true,
	logoPosition: 'top right',
	logoAlpha: parseFloat('0.6'),
	logoWidth: parseFloat('80'),
	logoHeight: parseFloat('40'),
	
	autoPlay: true,
	loop: true,
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
		if (propDefaults[name].toString().length==0) continue;
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
	  	if(typeof(Application.application.parameters[name])!='undefined') {
	  		if(name!='showDescriptions') loadSettings.push(name + '=' + encodeURI(Application.application.parameters[name]));
	  		if (typeof propDefaults[name]=='boolean') {
			 	props.put(name, new Boolean(parseFloat(Application.application.parameters[name])));
		 	} else {	
	  	    	if (isNaN(Application.application.parameters[name]) || name=='logoSource') {
			 		props.put(name, Application.application.parameters[name]);
	  	    	} else {
				 	props.put(name, parseFloat(Application.application.parameters[name]));
	  	    	}
	  	    }
	  	}
	}

	// Determine a load parameters
	var domain:String = URLUtil.getServerName(Application.application.url);
	if(domain=='localhost') domain=defaultDomain;
	props.put('domain', domain);
    var options:Array = ['photo_id', 'user_id', 'search', 'tag', 'tags', 'tag_mode', 'album_id', 'year', 'month', 'day', 'datemode', 'video_p video_encoded_p'];
    for (var i:int=0; i<options.length; i++) {
		var opt:String = options[i];
		if (Application.application.parameters[opt]) {
			loadParameters.push(opt + '=' + encodeURI(Application.application.parameters[opt]));
			loadSettings.push(opt + '=' + encodeURI(Application.application.parameters[opt]));
		}
    }
	if (defaultPhotoId.length) loadParameters.push('photo_id=' + encodeURI(defaultPhotoId)); 
	if (defaultAlbumId.length) loadParameters.push('album_id=' + encodeURI(defaultAlbumId)); 

	// Use load parameters to build JSON source
	var jsonSource:String = 'http://' + domain + '/js/photos?raw&' + loadParameters.join('&');
	props.put('jsonSource', jsonSource);

	var swfUrl:String = Application.application.loaderInfo.url;
	var swfHeight:Number = 567;
	var swfWidth:Number = 300;	
	var flashVars:String = loadSettings.join('&');
	embedPanel.embedTextValue = '<object width="' + swfWidth + '" height="' + swfHeight + '" style="width:' + swfWidth + 'px; height:' + swfHeight + 'px; " type="application/x-shockwave-flash" data="' + swfUrl + '"><param name="movie" value="' + swfUrl + '"></param><param name="FlashVars" value="' + flashVars + '"></param><param name="allowfullscreen" value="true"></param><param name="allowscriptaccess" value="always"></param></object>"';
	embedPanel.podcastLink = "itpc://"+domain+"/podcast/?" + loadParameters.join('&');
	embedPanel.rssLink = "http://"+domain+"/rss/?" + loadParameters.join('&');
	embedPanel.mailLink = "http://"+domain+"/send?popup_p=1&" + loadParameters.join('&');

	// Test logoSource
	if (props.get('logoSource')=='no logo' || props.get('logoSource')=='') props.put('logoSource', 'http://' + domain + '/files/sitelogo.gif');
	var logoRequest:URLRequest = new URLRequest((props.get('logoSource') as String));
	var logoLoader:URLLoader = new URLLoader();
	logoLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void {
		props.put('logoSource', ''); props.put('showLogo', false);
	});
	logoLoader.addEventListener(IOErrorEvent.IO_ERROR, function httpStatusHandler(e:Event):void {
		props.put('logoSource', ''); props.put('showLogo', false);
	});
	logoLoader.load(logoRequest);


	// Logo position
	var pos:String = props.get('logoPosition').toString();
	props.put('logoAlign', (new RegExp('left').test(pos) ? 'left' : 'right'));
	props.put('logoVAlign', (new RegExp('top').test(pos) ? 'top' : 'bottom'));
	
	// Should we start by playing HD? 
	if(props.get('playHD')) playHD = true;
}


