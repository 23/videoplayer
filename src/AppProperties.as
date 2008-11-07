// ActionScript file
import mx.utils.URLUtil;
[Bindable] public var props:HashCollection = new HashCollection()
public var propDefaults:Object = {
	backgroundColor: 'black',
	loadingColor: 'white',
	trayBackgroundColor: 'black',
	trayTextColor: 'white',
	trayFont: 'Arial, sans-serif',
	trayTitleFontSize: parseFloat('14'),
	trayTitleFontWeight: 'bold',
	trayTitleTextTranform: 'uppercase',
	trayContentFontSize: parseFloat('13'),
	trayContentFontWeight: 'normal',
	trayContentTextTranform: 'none',
	trayAlpha: parseFloat('0.5'),
	showTray: true,
	showDescriptions: true,
	autoPlay: false,
	logoSource: 'no logo',
	showLogo: true,
	logoPosition: 'top right',
	logoAlpha: parseFloat('0.85'),
	logoWidth: parseFloat('80'),
	logoHeight: parseFloat('40')
}
private function initProperties(settings:Object):void {
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

	// Determine a JSON source
	var domain:String = URLUtil.getServerName(Application.application.url);
	if(domain=='localhost') domain=defaultDomain;
	props.put('domain', domain);
	var jsonSource:String;
	if (Application.application.parameters.photo_id) {
		jsonSource = 'http://' + domain + '/js/photos?raw&photo_id=' + encodeURI(Application.application.parameters.photo_id); 
	} else if (Application.application.parameters.album_id) {
		jsonSource = 'http://' + domain + '/js/photos?raw&album_id=' + encodeURI(Application.application.parameters.album_id); 
	} else if (Application.application.parameters.tag) {
		jsonSource = 'http://' + domain + '/js/photos?raw&tag=' + encodeURI(Application.application.parameters.tag); 
	} else {
		jsonSource = 'http://' + domain + '/js/photos?raw'; 
	} 		 
	props.put('jsonSource', jsonSource);

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
}


