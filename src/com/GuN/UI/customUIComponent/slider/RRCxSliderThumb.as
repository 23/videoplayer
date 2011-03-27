package com.GuN.UI.customUIComponent.slider
{
	import com.GuN.UI.customUIComponent.slider.sprites.RRCxSprite;
	
	import flash.events.MouseEvent;
	
	import mx.controls.sliderClasses.Slider;
	import mx.controls.sliderClasses.SliderThumb;

	public class RRCxSliderThumb extends SliderThumb
	{
		var isMoving:Boolean = false;
		var spr:RRCxSprite;
		
		public function RRCxSliderThumb()
		{
			super();
			initListeners();
			initSprite();
			addChild(spr);
			
			
		}
		
		private function initListeners():void{
			addEventListener(MouseEvent.MOUSE_MOVE, myMouseMoveHandler);
		}
		
		private function myMouseMoveHandler(event:MouseEvent):void
			{
				
				if (isMoving)
				{
					spr.setValue(String(Slider(owner).value));
					
				}
			}
		
		override protected function mouseDownHandler(event:MouseEvent):void
			{
				super.mouseDownHandler(event);
				isMoving = true;
				
			}
			
		override protected function mouseUpHandler(event:MouseEvent):void
			{
				super.mouseUpHandler(event);
				isMoving = false;
            
			}
			
			
		private function initSprite():void{
			spr = new RRCxSprite();
			spr.x = 7;
			spr.y = 15;
		}
		
	}
}