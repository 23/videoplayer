package com.GuN.UI.customUIComponent.slider
{
	import com.GuN.UI.customUIComponent.slider.effect.FadeEffect;
	import com.GuN.UI.customUIComponent.slider.sprites.CSpSprite;
	
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	import mx.controls.sliderClasses.Slider;
	import mx.controls.sliderClasses.SliderThumb;

	public class CSpSliderThumb extends SliderThumb
	{
		var isMoving:Boolean = false;
		var spr:CSpSprite;
		var gfxFade:FadeEffect;
		var isDisplayed:Boolean = false;
		
			public function CSpSliderThumb()
			{
				super();
				useHandCursor = true;
			
			
			
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
            super.updateDisplayList(unscaledWidth,unscaledHeight);
            this.graphics.beginFill(0x333333,1);
            this.graphics.drawCircle(2,-8,4);
           	this.graphics.endFill();
        }
       
        
        override protected function measure():void{
            super.measure();
            measuredWidth = 4;
            measuredHeight = 4;
            measuredMinHeight = 0;
            measuredMinWidth = 0;
        }
        
       
		
	}
}