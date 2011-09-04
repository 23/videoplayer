package com.visual {
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
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
		// Public properties to play around with
		public var video:Object = null;
		public var connection:NetConnection = new NetConnection();
		public var stream:NetStream;
		public var fcSubscribeCount:int = 0;
		public var fcSubscribeMaxRetries:int = 3;
		private var isPlaying:Boolean = false;
				
		// Constructor method
		public function VisualVideo() {
			super();
			// Handle resize and progress
			this.addEventListener(ResizeEvent.RESIZE, matchVideoSize);
			setInterval(updateProgress, 200);
			// Listen for Stage Video events
			var $:Object = this;
			this.addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
				$.stage.addEventListener('stageVideoAvailability', function(e:Object):void{
					if(!$.video && enableStageVideo && e.availability=='available') {
						_displayMode = 'stage';
						$.video = $.stage.stageVideos[0];	
					}
				});
			});
		}

		// READ-ONLY PROPERTIES
		public function get playing():Boolean {return(this.state==VideoEvent.PLAYING);}
		private var _totalTime:Number = 0; 
		public function get totalTime():Number {return(_totalTime);}
		public function get bytesLoaded():Number {return(this.stream ? this.stream.bytesLoaded : 0);}
		public function get bytesTotal():Number {return(this.stream ? this.stream.bytesTotal : 0);}
		private var _videoWidth:int = 0; 
		public function get videoWidth():int {return(_videoWidth);}
		private var _videoHeight:int = 0; 
		public function get videoHeight():int {return(_videoHeight);}
		private var _displayMode:String = "standard";
		public function get displayMode():String {return(_displayMode);}
		
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
		private var _bufferTime:Number = 2;
		public function get bufferTime():Number {return(_bufferTime);}
		public function set bufferTime(bt:Number):void {if(_bufferTime>0) {_bufferTime=bt;}}
		
		public var enableStageVideo:Boolean = true;

		private var _aspectRatio:Number = 1; 
		private var _userAspectRatio:Number = 0; 
		private var _videoAspectRatio:Number = 16/9; 
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
			trace((new Date), "Swich source from", _source, 'to', s);
			_source=s;
			reset();
			trace((new Date), 'Done switching source');
		}
		
		public function get playheadTime():Number {return(this.stream ? this.stream.time : 0);}
		public function set playheadTime(pht:Number):void {
			if(!this.connection&&!this.stream) return;
			if(pht<0||pht>totalTime) return;
			if(isLive) return;
			this.stream.seek(pht);
		} 
		
		private var _state:String = VideoEvent.DISCONNECTED;
		public function get state():String {return(_state);}
		public function set state(s:String):void {
			_state = s;
			dispatchVideoEvent(VideoEvent.STATE_CHANGE);
		}		
		
		// PUBLIC METHODS
		public function close():void {this.stop();}
		public function stop():void {
			trace((new Date), 'stop()');
			if(this.stream) {
				this.stream.pause();
				this.stream.close();
				this.state = VideoEvent.STOPPED;
			}
		}
		public function play():void {
			trace((new Date), 'play()');
			if(!this.connection.connected) {
				trace((new Date), 'play() -> not connected');
				connect();
			} if(this.stream) {
				this.stream.resume();
				this.state = VideoEvent.PLAYING;
			}
		}
		public function pause():void {
			trace((new Date), 'pause()');
			if(this.stream) {
				this.stream.pause();
				this.state = VideoEvent.PAUSED;
			}
		}

		// STREAM EVENTS AND LOGIC
		private function reset():void {
			trace((new Date), 'reset()');
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
			trace((new Date), 'connect()');
			reset();
			this.state = VideoEvent.LOADING;
			this.fcSubscribeCount = 0;
			this.connection.connect(this.streamURL);
		}
		private function attachStreamToVideo():void {
			trace((new Date), 'attachStreamToVideo()');
			this.stream = new NetStream(this.connection);
			this.stream.soundTransform = new SoundTransform(_volume);
			this.stream.client = defaultClient;
			this.stream.bufferTime = _bufferTime;
			this.stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, genericErrorEvent);
			this.stream.addEventListener(IOErrorEvent.IO_ERROR, genericErrorEvent);
			this.stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			// Defaults for the video display
			if(!this.video) {
				var v:Video = new Video();
				v.smoothing = true;
				v.deblocking = 1;
				this.addChild(v);
				v.visible = true;
				this.video = v;	
			}
			this.video.attachNetStream(this.stream);
			this.state = VideoEvent.BUFFERING;
			this.stream.play(this.streamName);
			trace('displayMode = ', displayMode);
			matchVideoSize();
		}
		private function subscribe():void {
			trace((new Date), 'FCSubscribe()');
			this.connection.call("FCSubscribe", null, this.streamName);
		}

		private var defaultClient:Object = (function(context:Object):Object {
			return {
				onFCSubscribe:function(info:Object):void{
					trace((new Date), 'onFCSubscribe', info.code);
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
			this.state = VideoEvent.CONNECTION_ERROR;
		}
		private function netStatusHandler(event:NetStatusEvent):void {
			trace((new Date), 'netStatusHandler + ' + event.info.code);
			switch (event.info.code) {
				case "NetConnection.Connect.Rejected":
				case "NetConnection.Connect.IdleTimeout":
				case "NetConnection.Connect.Failed":
				case "NetStream.Connect.Failed":
				case "NetStream.Connect.Rejected":
				case "NetStream.Failed":
				case "NetStream.Play.Failed":
				case "NetStream.Play.StreamNotFound":
					this.state = VideoEvent.CONNECTION_ERROR;
					break;
				case "NetConnection.Connect.Closed":
					this.state = VideoEvent.DISCONNECTED;
					break;
				case "NetConnection.Connect.Success":
					this.state = VideoEvent.LOADING;
					if(this.isRTMP) {
						subscribe();
					} else {
						attachStreamToVideo();
					}
					break;
				case "NetStream.Buffer.Empty":
					if(isPlaying) this.state = VideoEvent.BUFFERING;
					break;
				case "NetStream.Seek.Notify":
				case "NetStream.Unpause.Notify":
				case "NetStream.Buffer.Full":
					break;
				case "NetStream.Play.Start":
					isPlaying = true;
					this.state = VideoEvent.PLAYING;
					break;
				case "NetStream.Pause.Notify":
					isPlaying = false;
					this.state = VideoEvent.PAUSED;
					break;
				case "NetStream.Play.Stop":
					isPlaying = false;
					this.state = VideoEvent.STOPPED;
					if(this.stream && totalTime>0 && this.stream.time>=(totalTime-0.5)) {
						dispatchVideoEvent(VideoEvent.COMPLETE);
					}
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
			trace((new Date), 'matchVideoSize()')
			if(this&&this.width&&this.video) {
				_aspectRatio = (_userAspectRatio && _userAspectRatio>0 ? _userAspectRatio : _videoAspectRatio);
				var stageAspectRatio:Number = this.width/this.height;
				var x:int, y:int, w:int, h:int = 0;
				if(stageAspectRatio>_aspectRatio) {
					h = this.height;
					w = this.height*_aspectRatio;
					x = (this.width-w)/2;
					y = 0;
				} else {
					w = this.width;
					h = this.width/_aspectRatio;
					x = 0;
					y = (this.height-h)/2;
				}
				if(displayMode=='stage') {
					this.video.viewPort = new Rectangle(x,y,w,h);
				} else {
					this.video.x = x;
					this.video.y = y;
					this.video.width = w;
					this.video.height = h;
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