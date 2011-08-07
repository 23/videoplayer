/* 

  A custom Flex Component for reporting VideoDisplay status 
  events to Gemius. Generally, the comoponent is designed to 
  be invoked with user credentials given by Gemius, and to
  work transparently by listening to VideoDisplay events. 
  
  Additionally, the component is designed to follow the 
  'Categorization rules for gemiusStream in Denmark' as defined
  by FDIM. 

  Set up a variable for the object:
    import Gemius;
    var gemiusStream:Gemius;
  Upon loading your application (after the VideoDisplay has loaded): 
    gemiusStream = new Gemius(video, '<your gemiusStream key>');
  To notify about content:
    gemiusStream.newString(id [, title, channel, totalTime, autoStart]);

  More info: @steffentchr, @23video and github.com/23

*/

package com {
	import flash.events.ErrorEvent;
	
	import gemius.gSmConnectorMediator;
	
	import mx.events.VideoEvent;

	public class Gemius {
		// Set up component properties
		public var gemiusIdentifier:String = ''; 
		public var gemiusHitcollector:String = 'gadk.hit.gemius.pl';
		public var gemiusPublisherID:String = '000';

		public var videoStartOffset:Number = 0;
		
		private var playerId:String = "visualplatformplayer_" + Math.round(Math.random()*1000000);
		private var materialIdentifier:String = '';
		private var contentID:Number;
		private var contentTitle:String;
		private var contentChannel:String;
		private var contentTotalTime:Number;
		private var contentAutoStart:Boolean;
		private var video:VideoDisplay;
		
		import mx.controls.VideoDisplay;
		
		// Constructor for the Flex component
		public function Gemius(videoDisplay:VideoDisplay, identifier:String, hitcollector:String = 'gadk.hit.gemius.pl', publisherID:String = '000') {
			super();
			
			// Store public properties
			gemiusIdentifier = identifier;
			gemiusHitcollector = hitcollector;
			publisherID = gemiusPublisherID;
			video = videoDisplay;
			// Power the stream mediator
			gSmConnectorMediator.setEncoding("utf-8");
			gSmConnectorMediator.setGSMIdentifier(gemiusIdentifier);
			gSmConnectorMediator.setGSMHitcollector(gemiusHitcollector);
			
			trace(video.source);
			trace(video.addEventListener);
			try {
				video.addEventListener(VideoEvent.CLOSE, function():void{closeStream();});
				video.addEventListener(VideoEvent.BUFFERING, function():void{event('buffering');});
				video.addEventListener(VideoEvent.COMPLETE, function():void{event('complete');});
				video.addEventListener(VideoEvent.LOADING, function():void{event('seekingStarted');});
				video.addEventListener(VideoEvent.PAUSED, function():void{event('paused');});
				video.addEventListener(VideoEvent.PLAYING, function():void{event('playing');});
				video.addEventListener(VideoEvent.SEEKING, function():void{event('seekingStarted');});
				video.addEventListener(VideoEvent.STOPPED, function():void{event('stopped');});
			}catch(e:ErrorEvent){trace(e);}
		}

		public function newStream(id:int, title:String = '', channel:String = 'Default', totalTime:Number = 0, autoStart:Boolean = false):void {
			// Save properties
			contentID = id;
			contentTitle = title;
			contentChannel = channel;
			contentTotalTime = totalTime||video.totalTime;
			contentAutoStart = autoStart;

			// Properties about the player and it's material
			materialIdentifier = gemiusPublisherID + '_' + contentID.toString(16) + '&' + contentTitle.replace(/&/img, ' ');

			// Custom package of information, required by Danish FDIM.
			var customPackage:Array = new Array(); 
			customPackage.push({name:'AUTOSTART', value:(contentAutoStart?'YES':'NO')}); 
			customPackage.push({name:"CHANNEL", value:contentChannel}); 
			customPackage.push({name:"PROGRAMME", value:contentChannel.toLocaleUpperCase()});

			// Report that there's a new stream
			trace('Gemius new');
			gSmConnectorMediator.newStream(playerId, materialIdentifier, contentTotalTime, customPackage, [], []);
			event('playing');
		}  

		public function closeStream():void {
			trace('Gemius close');
			gSmConnectorMediator.closeStream(playerId, materialIdentifier, video.playheadTime+videoStartOffset);
		}
		public function event(event:String):void {
			try {
				trace('Gemius: ' + event);
				gSmConnectorMediator.event(playerId, materialIdentifier, video.playheadTime+videoStartOffset, event);
			}catch(e:ErrorEvent){trace(e);}
		}
	}
}