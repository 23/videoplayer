package com.visual {
	import com.google.ads.instream.api.Ad;
	import com.google.ads.instream.api.AdErrorEvent;
	import com.google.ads.instream.api.AdEvent;
	import com.google.ads.instream.api.AdLoadedEvent;
	import com.google.ads.instream.api.AdSizeChangedEvent;
	import com.google.ads.instream.api.AdsLoadedEvent;
	import com.google.ads.instream.api.AdsLoader;
	import com.google.ads.instream.api.AdsManager;
	import com.google.ads.instream.api.AdsManagerTypes;
	import com.google.ads.instream.api.AdsRequest;
	import com.google.ads.instream.api.FlashAdsManager;
	import com.google.ads.instream.api.VerticalAlignment;
	import com.google.ads.instream.api.VideoAdsManager;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Video;
	import flash.net.NetStream;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	[Event(name="contentPauseRequested", type="flash.events.Event")]
	[Event(name="contentResumeRequested", type="flash.events.Event")]
	
	public class VisualAds extends UIComponent {
		private var loader:AdsLoader;
		private var manager:AdsManager;
		private var requests:Array = [];
		private var internalFlash:UIComponent = null;
		private var internalVideo:Video = null;
		private var ns:NetStream = null;
		
		public function VisualAds() {
			super();
			this.visible = false;
			this.addEventListener(ResizeEvent.RESIZE, handleChildrenSizes);
			
			// Google IMA Loader
			loader = new AdsLoader();
			loader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
			loader.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
		}
		public function push(type:String, url:String, publisherId:String = '', contentId:String = ''):void {
			requests.push({type:type, url:url, publisherId:publisherId, contentId:contentId});
		}
		public function preroll():Boolean {
			return(this.load('video'));
		}
		public function overlay():Boolean {
			return(this.load('overlay'));
		}
		public function postroll():Boolean {
			return(this.load('video'));
		}
		private function load(type:String):Boolean {
			for (var i:int=0; i<requests.length; i++){
				var req:Object = requests[i];
				try {
					if(typeof(req.type)!='undefined' && req.type==type) {
						var request:AdsRequest = new AdsRequest();
						request.adType = req.type;
						request.adTagUrl = req.url;
						request.publisherId = req.publisherId;
						request.contentId = req.contentId;
						request.adSlotWidth = this.width;
						request.adSlotHeight = this.height;
						requests.push(request);
						loader.requestAds(request);
						this.visible = true;
						return(true);
					}
				}catch(e:Object){}
			}
			return(false);
		}
		private function onContentPauseRequested(e:AdEvent):void {
			dispatchEvent(new Event('contentPauseRequested'));
		}
		private function onContentResumeRequested(e:AdEvent):void {
			dispatchEvent(new Event('contentResumeRequested'));
		}
		private function onAdError(e:AdErrorEvent):void {
			trace('VisualAd Error:', e.error.errorMessage);
			onContentResumeRequested(null);
		}
		private function onFlashAdSizeChanged(e:AdSizeChangedEvent):void {
			trace('onFlashAdSizeChanged', e);
		}
		private function onVideoAdComplete(e:AdEvent):void {
			// Remove video element if applicable
			(manager as VideoAdsManager).clickTrackingElement = null;
			this.internalVideo.visible = false;
			this.internalVideo.clear();
		}
		
		private function onAdLoaded(e:AdLoadedEvent):void {
			ns = e.netStream;
		}

		private function onAdsLoaded(e:AdsLoadedEvent):void {
			// Clear previous Flash ad stages
			try {
				if(this.internalFlash) this.removeChild(this.internalFlash);
			}catch(e:ArgumentError){trace(e);}

			manager = e.adsManager;
			manager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			manager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED, onContentPauseRequested);
			manager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED, onContentResumeRequested);
			manager.addEventListener(AdLoadedEvent.LOADED, onAdLoaded);
			
			if (manager.type == AdsManagerTypes.FLASH) {
				var flashAdsManager:FlashAdsManager = e.adsManager as FlashAdsManager;
				flashAdsManager.addEventListener(AdSizeChangedEvent.SIZE_CHANGED, onFlashAdSizeChanged);
				this.internalFlash = new UIComponent();
				this.addChild(this.internalFlash);
				var point:Point = this.internalFlash.localToGlobal(new Point(this.internalFlash.x, this.internalFlash.y));
				flashAdsManager.x = point.x;
				flashAdsManager.y = point.y;
				flashAdsManager.load();
				flashAdsManager.play(this.internalFlash);
			} else if (manager.type == AdsManagerTypes.VIDEO) {
				var videoAdsManager:VideoAdsManager = e.adsManager as VideoAdsManager;
				videoAdsManager.addEventListener(AdEvent.COMPLETE, onVideoAdComplete); 
				videoAdsManager.clickTrackingElement = this;

				// Add a video element to play within
				if(!internalVideo) {
					internalVideo = new Video();
					internalVideo.smoothing = true;
					internalVideo.deblocking = 1;
					this.addChild(internalVideo);
				}
				handleChildrenSizes();
				videoAdsManager.load(this.internalVideo);
				this.internalVideo.visible = true;
				videoAdsManager.play(this.internalVideo);
			} else if (manager.type == AdsManagerTypes.CUSTOM_CONTENT) {
				// Not supported
			}
		}
		
		private function handleChildrenSizes(e:ResizeEvent=null):void {
			// Video is simple, just fill the screen
			if(this&&this.width&&this.internalVideo) {
				this.internalVideo.width = this.width;
				this.internalVideo.height = this.height;
			}
			// For Flash ads, we need to also resize the place holder
			if (manager && this.internalFlash && manager.type == AdsManagerTypes.FLASH) {
				var flashAdsManager:FlashAdsManager = manager as FlashAdsManager;
				var point:Point = this.internalFlash.localToGlobal(new Point(this.internalFlash.x, this.internalFlash.y));
				flashAdsManager.x = point.x;
				flashAdsManager.y = point.y;
				flashAdsManager.adSlotHeight = this.height;
				flashAdsManager.adSlotWidth = this.width;
			}
		}
		
		public function stop():void{
			try {
				manager.unload();
				if(ns) ns.close();
				onVideoAdComplete(null);
			}catch(e:Object){}
			dispatchEvent(new Event('contentResumeRequested'));
		}
	}
}