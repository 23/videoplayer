// TODO:
// - Play state på live streams
// - Live stream menu, not selected
// - Image previews

package com.visual {
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.events.VideoEvent;

	[Event(name="complete", type="mx.events.VideoEvent")]
	[Event(name="stateChange", type="mx.events.VideoEvent")]
	[Event(name="playheadUpdate", type="mx.events.VideoEvent")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="volumeChanged", type="mx.events.VideoEvent")]
	
	public class VisualVideo extends UIComponent {
		// CONSTANTS
		public static const DISCONNECTED:String = "disconnected";
		public static const STOPPED:String = "stopped";
		public static const PLAYING:String = "playing";
		public static const PAUSED:String = "paused";
		public static const BUFFERING:String = "buffering";
		public static const LOADING:String = "loading";
		public static const CONNECTION_ERROR:String = "connectionError";
		public static const SEEKING:String = "seeking";

		// Public properties to play around with
		public var video:Video = new Video();
		public var connection:NetConnection = new NetConnection();
		public var stream:NetStream;
		public var fcSubscribeCount:int = 0;
		public var fcSubscribeMaxRetries:int = 3;
		
		// Constructor method
		public function VisualVideo() {
			super();
			// Handle resize and progress
			this.addEventListener(ResizeEvent.RESIZE, matchVideoSize);
			setInterval(updateProgress, 200);
			// Defaults for the video display
			video.smoothing = true;
			video.deblocking = 1;
		}

		// READ-ONLY PROPERTIES
		public function get playing():Boolean {return(state==PLAYING);}
		private var _totalTime:Number = 0; 
		public function get totalTime():Number {return(_totalTime);}
		public function get bytesLoaded():Number {return(this.stream ? this.stream.bytesLoaded : 0);}
		public function get bytesTotal():Number {return(this.stream ? this.stream.bytesTotal : 0);}
		private var _videoWidth:int = 0; 
		public function get videoWidth():int {return(_videoWidth);}
		private var _videoHeight:int = 0; 
		public function get videoHeight():int {return(_videoHeight);}
		
		// Is this an RTMP stream?
		public function get isLive():Boolean {return(isRTMP);}
		public function get isRTMP():Boolean {
			if(_source) {
				return(/^rtmp:\/\//.test(_source.toLowerCase()));
			} else {
				return(false);
			}
		}
		private function splitRTMPSource():Array {
			var match:Array = _source.match(/^(.+\/)([^\/]+)/);
			if(match.length==3) {
				return [match[1], match[2]];
			} else {
				return [null, _source];
			}
		}
		public function get streamURL():String {
			if(this.isRTMP) {
				return(splitRTMPSource()[0]);
			} else {
				return(null);
			}
		}
		public function get streamName():String {
			if(this.isRTMP) {
				return(splitRTMPSource()[1]);
			} else {
				return(_source);
			}
		}

		// READ-WRITE PROPERTIES
		private var _bufferTime:int = 2;
		public function get bufferTime():int {return(_bufferTime);}
		public function set bufferTime(bt:int):void {if(_bufferTime>0) {_bufferTime=bt;}}

		private var _aspectRatio:Number = 1; 
		private var _userAspectRatio:Number; 
		private var _videoAspectRatio:Number; 
		public function get aspectRatio():Number {return(_aspectRatio);}
		public function set aspectRatio(ar:Number):void {_userAspectRatio=ar; matchVideoSize();}

		private var _volume:Number = 1;
		[Bindable("volumeChanged")] public function get volume():Number {return(_volume);}
		public function set volume(v:Number):void {
			if (_volume != v) {
				_volume = v;
				if(this.stream) this.stream.soundTransform = new SoundTransform(_volume);
				dispatchEvent(new Event("volumeChanged"));
			}
		}

		private var _source:String = null;
		public function get source():String {return(_source);}
		public function set source(s:String):void {
			if(_source==s) return;
			_source=s;
			reset();
		}
		
		public function get playheadTime():Number {return(this.stream ? this.stream.time : 0);}
		public function set playheadTime(pht:Number):void {
			if(!this.connection&&!this.stream) return;
			if(pht<0||pht>totalTime) return;
			if(isLive) return;
			this.stream.seek(pht);
		} 
		
		private var _state:String = DISCONNECTED;
		public function get state():String {return(_state);}
		public function set state(s:String):void {
			_state = s;
			dispatchVideoEvent(VideoEvent.STATE_CHANGE);
		}		
		
		// PUBLIC METHODS
		public function close():void {this.stop();}
		public function stop():void {
			if(this.stream) {
				this.stream.pause();
				this.stream.close();
				this.state = STOPPED;
			}
		}
		public function play():void {
			if(!this.connection.connected) {
				connect();
			} if(this.stream) {
				this.stream.resume();
				this.state = PLAYING;
			}
		}
		public function pause():void {
			if(this.stream) {
				this.stream.pause();
				this.state = PAUSED;
			}
		}

		// STREAM EVENTS AND LOGIC
		private function reset():void {
			stop();
			// Reset progress
			_totalTime = 0;
			_lastProgressBytes = 0;
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, 0, 0));
			dispatchVideoEvent(VideoEvent.PLAYHEAD_UPDATE);
			// Reset aspectRatio (but maintain _userAspectRatio)
			_aspectRatio = 1;
			_videoAspectRatio = 1;
			// Stop stream
			this.stream = null;
			// Prepare the net connection object
			this.connection = new NetConnection();
			this.connection.client = defaultClient;
			this.connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityErrorHandler);
		}
		private function connect():void {
			reset();
			this.state = LOADING;
			this.fcSubscribeCount = 0;
			this.connection.connect(this.streamURL);
		}
		private function attachStreamToVideo():void {
			this.stream = new NetStream(this.connection);
			this.stream.soundTransform = new SoundTransform(_volume);
			this.stream.client = defaultClient;
			this.stream.bufferTime = _bufferTime;
			this.stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, genericErrorEvent);
			this.stream.addEventListener(IOErrorEvent.IO_ERROR, genericErrorEvent);
			this.stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.video.attachNetStream(this.stream);
			this.video.visible = true;
			this.state = BUFFERING;
			this.stream.play(this.streamName);
			this.addChild(this.video);
			matchVideoSize();
		}
		private function subscribe():void {
			this.connection.call("FCSubscribe", null, this.streamName);
		}

		private var defaultClient:Object = (function(context:Object):Object {
			return {
				onFCSubscribe:function(info:Object):void{
					switch(info.code){
						case "NetStream.Play.StreamNotFound":
							if(fcSubscribeCount >= fcSubscribeMaxRetries){
								fcSubscribeCount = 0;
							} else {
								fcSubscribeCount++;
								setTimeout(context.subscribe, 1000);
							}
							break;
						case "NetStream.Play.Start":
							fcSubscribeCount = 0;
							context.attachStreamToVideo();
							break;
					}				
				},
				onFCUnsubscribe:function(info:Object):void{},
				onMetaData:function(item:Object):void{
					try {
						_videoHeight = item.height;
						_videoWidth = item.width;
						_videoAspectRatio = item.width/item.height;
						matchVideoSize();
					}catch(e:ErrorEvent){_aspectRatio=1;}
					try {
						_totalTime = item.duration;
					}catch(e:ErrorEvent){_totalTime=0;}
				}
			}
		})(this);
		
		private function genericErrorEvent(event:Event):void {
			trace('Error', event.type);
			this.state = CONNECTION_ERROR;
		}
		private function netStatusHandler(event:NetStatusEvent):void {
			trace('netStatusHandler + ' + event.info.code);
			switch (event.info.code) {
				case "NetConnection.Connect.Rejected":
				case "NetConnection.Connect.IdleTimeout":
				case "NetConnection.Connect.Failed":
				case "NetStream.Connect.Failed":
				case "NetStream.Connect.Rejected":
				case "NetStream.Failed":
				case "NetStream.Play.Failed":
				case "NetStream.Play.StreamNotFound":
					this.state = CONNECTION_ERROR;
					break;
				case "NetConnection.Connect.Closed":
					this.state = DISCONNECTED;
					break;
				case "NetConnection.Connect.Success":
					this.state = LOADING;
					if(this.isRTMP) {
						subscribe();
					} else {
						attachStreamToVideo();
					}
					break;
				case "NetStream.Buffer.Empty":
					this.state = BUFFERING;
					break;
				case "NetStream.Buffer.Full":
				case "NetStream.Seek.Notify":
				case "NetStream.Unpause.Notify":
				case "NetStream.Play.Start":
					this.state = PLAYING;
					break;
				case "NetStream.Pause.Notify":
					this.state = PAUSED;
					break;
				case "NetStream.Play.Stop":
					this.state = STOPPED;
					break;
			}
		}			
		private function netSecurityErrorHandler(event:SecurityErrorEvent):void {}
		private function dispatchVideoEvent(ev:String):void {
			var videoEvent:VideoEvent = new VideoEvent(ev);
			videoEvent.state = this.state;
			videoEvent.playheadTime = this.playheadTime;
			dispatchEvent(videoEvent);
		}
		
		// Match size of video to the container
		private function matchVideoSize(e:ResizeEvent=null):void {
			if(this&&this.width) {
				_aspectRatio = (_userAspectRatio ? _userAspectRatio : _videoAspectRatio);
				var stageAspectRatio:Number = this.width/this.height;
				if(stageAspectRatio>_aspectRatio) {
					video.height = this.height;
					video.width = this.height*_aspectRatio;
					video.x = (this.width-video.width)/2;
					video.y = 0;
				} else {
					video.width = this.width;
					video.height = this.width/_aspectRatio;
					video.x = 0;
					video.y = (this.height-video.height)/2;
				}
			}
		}
		// Handle progress bar
		private var _lastProgressBytes:int = 0;
		private var _lastProgressTime:int = 0;
		private function updateProgress():void {
			if(!this.connection||!this.stream) return;
			if(this.stream.bytesTotal >= 0 && this.stream.bytesLoaded != _lastProgressBytes) {
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, this.stream.bytesLoaded, this.stream.bytesTotal));
			}
			// Actually, this should probably be time>=0 rather than time>0, but I 
			// don't like my scrubber jumping back when switching streams. Fugly.
			if(this.stream.time > 0 && this.stream.time != _lastProgressTime) {
				dispatchVideoEvent(VideoEvent.PLAYHEAD_UPDATE);
			}
			_lastProgressBytes = this.stream.bytesLoaded;
			_lastProgressTime = this.stream.time;
		}
	}
}