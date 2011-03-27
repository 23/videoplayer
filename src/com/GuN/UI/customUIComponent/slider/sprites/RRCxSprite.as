package com.GuN.UI.customUIComponent.slider.sprites
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class RRCxSprite extends Sprite
	{
		var lbl:TextField;
		var bkgColor:uint = 0x000000;
		var bkgAlpha:Number = .5;
		
		var textColor:uint = 0xFFFFFF;
		
		public function RRCxSprite()
		{
			super();
			lbl = new TextField();
			drawShape();
			drawText();
		}
		
		private function drawText():void{
			lbl.x = -10;
			lbl.y = 3;
			lbl.autoSize = TextFieldAutoSize.CENTER;
            lbl.background = false;
            lbl.border = false;

            var format:TextFormat = new TextFormat();
            format.font = "Verdana";
            format.color = textColor;
            format.size = 9;
            format.underline = false;

            lbl.defaultTextFormat = format;
            addChild(lbl);
		}
		
		private function drawShape():void
		{
			
			this.graphics.beginFill(bkgColor,bkgAlpha);
			this.graphics.drawRoundRectComplex(0,0,80,20,0,10,10,10);
			this.graphics.endFill();
					
		}
		
		public function setValue(v:String):void{
			lbl.text = v;
		}
		
	}
}