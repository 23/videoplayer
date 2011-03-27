package com.GuN.UI.customUIComponent.slider.sprites
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class CSpSprite extends Sprite
	{
		var lbl:TextField;
		var bkgColor:uint = 0x000000;
		var bkgAlpha:Number = .5;
		
		var textColor:uint = 0xFFFFFF;
		
		public function CSpSprite()
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
			this.graphics.lineTo(35,0);
			this.graphics.lineTo(40,-9);
			this.graphics.lineTo(45,0);
			this.graphics.lineTo(80,0);
			this.graphics.lineTo(80,25);
			this.graphics.lineTo(0,25);
			this.graphics.lineTo(0,0);
			this.graphics.endFill();
			
			
			//Create a white border
			this.graphics.lineStyle(1, 0xFFFFFF, 1);
			this.graphics.moveTo(-1,-1);
			this.graphics.lineTo(34,-1);
			this.graphics.lineTo(39,-10);
			this.graphics.lineTo(44,-1);
			this.graphics.lineTo(79,-1);
			this.graphics.lineTo(79,24);
			this.graphics.lineTo(-1,24);
			this.graphics.lineTo(-1,-1);
			
					
		}
		
		public function setValue(v:String):void{
			lbl.text = v;
		}
		
	}
}