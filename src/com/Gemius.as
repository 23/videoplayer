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
	import flash.events.Event;
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
		public var videoComponent:VideoDisplay;
		
		import mx.controls.VideoDisplay;
		
		// Constructor for the Flex component
		public function Gemius(video:VideoDisplay, identifier:String, hitcollector:String = 'gadk.hit.gemius.pl', publisherID:String = '000') {
			super();

			// Store public properties
			gemiusIdentifier = identifier;
			gemiusHitcollector = hitcollector;
			publisherID = gemiusPublisherID;
			videoComponent = video;
			// Power the stream mediator
			gSmConnectorMediator.setEncoding("utf-8");
			gSmConnectorMediator.setGSMIdentifier(gemiusIdentifier);
			gSmConnectorMediator.setGSMHitcollector(gemiusHitcollector);
			
			videoComponent.addEventListener(VideoEvent.COMPLETE, function(e:VideoEvent):void{
					closeStream();
				});
			videoComponent.addEventListener(VideoEvent.STATE_CHANGE, function(e:VideoEvent):void{
					event(e.state!='seeking' ? e.state : 'seekingStarted');
				});
		}

		public function newStream(id:int, title:String = '', channel:String = 'Default', totalTime:Number = 0, autoStart:Boolean = false):void {
			// Save properties
			contentID = id;
			contentTitle = title;
			contentChannel = channel;
			contentTotalTime = totalTime||videoComponent.totalTime;
			contentAutoStart = autoStart;

			// Properties about the player and it's material
			materialIdentifier = gemiusPublisherID + '_' + contentID.toString(16) + '&' + contentTitle.replace(/&/img, ' ');

			// Custom package of information, required by Danish FDIM.
			var customPackage:Array = new Array(); 
			customPackage.push({name:'AUTOSTART', value:(contentAutoStart?'YES':'NO')}); 
			customPackage.push({name:"CHANNEL", value:contentChannel}); 
			customPackage.push({name:"PROGRAMME", value:contentChannel.toLocaleUpperCase()});

			// Report that there's a new stream
			trace('Gemius: newStream()');
			gSmConnectorMediator.newStream(playerId, materialIdentifier, contentTotalTime, customPackage, [], []);
		}  

		public function closeStream():void {
			trace('Gemius: closeStream()/complete event');
			gSmConnectorMediator.closeStream(playerId, materialIdentifier, videoComponent.playheadTime+videoStartOffset);
		}
		public function event(event:String):void {
			var time:Number = videoComponent.playheadTime+videoStartOffset;
			trace('Gemius: ' + event + ' event at ' + time);
			gSmConnectorMediator.event(playerId, materialIdentifier, time, event);
		}
	}
}