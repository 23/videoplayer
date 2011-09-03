import com.adobe.serialization.json.JSON;
import com.adobe.serialization.json.JSONParseError;
private function doJSON(url:String, f:Function):URLLoader {
   	var loader:URLLoader = new URLLoader();
	loader.addEventListener(Event.COMPLETE, function(e:Event):void {f(JSON.decode(loader.data));});
	loader.load(new URLRequest(url));
	return(loader);
}
private function doAPI(method:String, parameters:Object, f:Function):URLLoader {
	parameters['raw'] = 't';
	parameters['format'] = 'json';
	if(!props.get('site_url')) initLoadURL();
	var url:String = props.get('site_url') + method + '?' + toQueryString(parameters);
	return doJSON(url, f);
}
private function toQueryString(o:Object):String {
	var a:Array = [];
	var names:Array = [];
	for (var s:String in o) names.push(s);
	names.sort();
	var x:String;
	for (var i:int=0; i<names.length; i++) {
		x = names[i];
		a.push(encodeURIComponent(x) + '=' + encodeURIComponent(o[x]));
	}
	return(a.join('&'));
}
