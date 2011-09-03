package preload {
	import flash.display.Loader;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	public class CustomPreloaderScreen extends Loader {
		[Embed(source="preloader.swf", mimeType="application/octet-stream")] public var CustomPreloaderGraphic:Class;
		public var timer:Timer;
		public var ready:Boolean = false; 
		
		public function CustomPreloaderScreen() {
			timer = new Timer(1);
            timer.addEventListener(TimerEvent.TIMER, updateView);
			timer.start();
			this.loadBytes(new CustomPreloaderGraphic() as ByteArray);
		}
		
		public function updateView(t:TimerEvent):void {
			this.stage.addChild(this)
			this.x = this.stage.stageWidth/2 - this.width/2
			this.y = this.stage.stageHeight/2 - this.height/2
			this.visible=true;
			if(this.ready) {	
            	timer.removeEventListener(TimerEvent.TIMER, updateView);
            	timer.stop();
            	this.visible = false;
   			}
		}
	}
}