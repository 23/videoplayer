package com.GuN.UI.customUIComponent.slider
{
	import mx.core.UIComponent;

	public class SliderTrack extends UIComponent
	{
			override public function get height():Number{
	            return 20;
	        }
        
        
        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
            super.updateDisplayList(unscaledWidth, unscaledHeight);
            this.graphics.beginFill(0x333333,1);
            this.graphics.drawCircle(0,0,5);
            this.graphics.drawCircle(unscaledWidth,0,5);
            this.graphics.endFill();
            
            this.graphics.moveTo(0,0);
            this.graphics.lineStyle(10,0x333333);
            this.graphics.lineTo(unscaledWidth,0);
           
        }
		
	}
}