package preload {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.getTimer;
	
	import mx.events.*;
	import mx.preloaders.DownloadProgressBar;

	public class CustomPreloader extends DownloadProgressBar {
        public var beginBytes:int, beginTime:int;                                                                                                                       
        public static var kbps:Number = 2000;
         
        public var cps:CustomPreloaderScreen;
        public function CustomPreloader() {
            super(); 
            cps = new CustomPreloaderScreen();
            this.addChild(cps)                   
        }
    
        override public function set preloader(preloader:Sprite):void {
            preloader.addEventListener(ProgressEvent.PROGRESS, SWFDownloadProgress);    
            preloader.addEventListener(Event.COMPLETE, SWFDownloadComplete);
            preloader.addEventListener(FlexEvent.INIT_PROGRESS, FlexInitProgress);
            preloader.addEventListener(FlexEvent.INIT_COMPLETE, FlexInitComplete);
        }
    
        private function SWFDownloadProgress(event:ProgressEvent):void {
        	if(typeof(beginTime)=='undefined') { 
            	beginTime = getTimer();                                                                                                                           
              	beginBytes = event.bytesLoaded;                                                                                                                   
			} else {                                                                                                                                                
				kbps = Math.floor( ((event.bytesLoaded-beginBytes) * 8 / 1024) / ((getTimer()-beginTime)/1000) );                                               
			} 
        }
        private function SWFDownloadComplete(event:Event):void {}
        private function FlexInitProgress(event:Event):void {}
       	private function FlexInitComplete(event:FlexEvent):void {
        	cps.ready = true;  	
            dispatchEvent(new Event(Event.COMPLETE));
        }
 	}
}